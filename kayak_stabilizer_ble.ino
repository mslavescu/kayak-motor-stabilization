#include <Wire.h>
#include <MPU6050.h>
#include <ESP32Servo.h>
#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include <BLE2902.h>
#include <Preferences.h>

// Pin definitions
#define SERVO_LEFT_PIN 12
#define SERVO_RIGHT_PIN 13
#define EMERGENCY_BUTTON_PIN 14
#define WATERPROOF_BUTTON_PIN 15
#define BATTERY_VOLTAGE_PIN 34
#define BATTERY_TYPE_PIN 35  // Analog pin to detect battery type

// BLE UUIDs
#define SERVICE_UUID "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID_DATA "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define CHARACTERISTIC_UUID_COMMAND "beb5483f-36e1-4688-b7f5-ea07361b26a8"

// System constants
#define IMU_UPDATE_RATE 100  // Hz
#define PID_UPDATE_RATE 50   // Hz
#define MAX_SERVO_ANGLE 30   // degrees
#define BUTTON_DEBOUNCE_TIME 50  // ms
#define BLE_UPDATE_RATE 10   // Hz

// Battery constants
#define LI_PO_LOW_VOLTAGE 3.3  // V
#define DRILL_18V_LOW_VOLTAGE 14.0  // V (after regulator)
#define DRILL_20V_LOW_VOLTAGE 16.0  // V (after regulator)

// PID parameters (adjustable via BLE)
float Kp = 2.0;
float Ki = 0.1;
float Kd = 0.5;

// Global variables
MPU6050 mpu;
Servo servoLeft, servoRight;
Preferences preferences;

BLEServer* pServer = NULL;
BLECharacteristic* pDataCharacteristic = NULL;
BLECharacteristic* pCommandCharacteristic = NULL;

float roll, pitch, yaw;
float rollError, pitchError;
float rollIntegral = 0, pitchIntegral = 0;
float rollPrevError = 0, pitchPrevError = 0;
unsigned long lastImuUpdate = 0;
unsigned long lastPidUpdate = 0;
unsigned long lastBleUpdate = 0;
bool emergencyStop = false;
bool stabilizationEnabled = false;
float batteryVoltage = 0;
int batteryType = 0;  // 0=LiPo, 1=18V Drill, 2=20V Drill

// Button debouncing
unsigned long lastEmergencyButtonPress = 0;
unsigned long lastWaterproofButtonPress = 0;
bool emergencyButtonState = false;
bool waterproofButtonState = false;
bool lastEmergencyButtonReading = false;
bool lastWaterproofButtonReading = false;

// BLE connection status
bool deviceConnected = false;
bool oldDeviceConnected = false;

// BLE callback classes
class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
        deviceConnected = true;
        Serial.println("BLE Device connected");
    }

    void onDisconnect(BLEServer* pServer) {
        deviceConnected = false;
        Serial.println("BLE Device disconnected");
    }
};

class MyCommandCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
        std::string value = pCharacteristic->getValue();
        if (value.length() > 0) {
            String command = String(value.c_str());
            processCommand(command);
        }
    }
};

void setup() {
    Serial.begin(115200);
    Wire.begin();

    // Initialize IMU
    mpu.initialize();
    if (!mpu.testConnection()) {
        Serial.println("MPU6050 connection failed!");
        while (1);
    }

    // Initialize servos
    servoLeft.attach(SERVO_LEFT_PIN);
    servoRight.attach(SERVO_RIGHT_PIN);
    servoLeft.write(90);  // Center position
    servoRight.write(90);

    // Initialize preferences for storing settings
    preferences.begin("stabilizer", false);

    // Load PID parameters from preferences
    Kp = preferences.getFloat("Kp", 2.0);
    Ki = preferences.getFloat("Ki", 0.1);
    Kd = preferences.getFloat("Kd", 0.5);
    stabilizationEnabled = preferences.getBool("stabilizationEnabled", false);

    // Setup button pins
    pinMode(EMERGENCY_BUTTON_PIN, INPUT_PULLUP);
    pinMode(WATERPROOF_BUTTON_PIN, INPUT_PULLUP);

    // Initialize BLE
    setupBLE();

    Serial.println("Kayak Stabilization System with BLE Initialized");
}

void loop() {
    unsigned long currentTime = millis();

    // Handle BLE connection status
    handleBLEConnection();

    // Check buttons with debouncing
    checkEmergencyButton();
    checkWaterproofButton();

    // Update IMU data
    if (currentTime - lastImuUpdate >= 1000 / IMU_UPDATE_RATE) {
        updateIMU();
        lastImuUpdate = currentTime;
    }

    // Update PID control
    if (currentTime - lastPidUpdate >= 1000 / PID_UPDATE_RATE) {
        updatePID();
        lastPidUpdate = currentTime;
    }

    // Update battery monitoring
    checkBattery();

    // Send BLE data
    if (currentTime - lastBleUpdate >= 1000 / BLE_UPDATE_RATE && deviceConnected) {
        sendBLEData();
        lastBleUpdate = currentTime;
    }

    delay(10);  // Small delay to prevent overwhelming the processor
}

void setupBLE() {
    BLEDevice::init("KayakStabilizer");
    pServer = BLEDevice::createServer();
    pServer->setCallbacks(new MyServerCallbacks());

    BLEService *pService = pServer->createService(SERVICE_UUID);

    // Create data characteristic (notify)
    pDataCharacteristic = pService->createCharacteristic(
        CHARACTERISTIC_UUID_DATA,
        BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
    );
    pDataCharacteristic->addDescriptor(new BLE2902());

    // Create command characteristic (write)
    pCommandCharacteristic = pService->createCharacteristic(
        CHARACTERISTIC_UUID_COMMAND,
        BLECharacteristic::PROPERTY_WRITE
    );
    pCommandCharacteristic->setCallbacks(new MyCommandCallbacks());

    pService->start();

    BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->setScanResponse(true);
    pAdvertising->setMinPreferred(0x06);
    pAdvertising->setMinPreferred(0x12);
    BLEDevice::startAdvertising();

    Serial.println("BLE setup complete");
}

void handleBLEConnection() {
    if (!deviceConnected && oldDeviceConnected) {
        delay(500); // Give the bluetooth stack time to get ready
        pServer->startAdvertising(); // Restart advertising
        Serial.println("BLE Restart advertising");
        oldDeviceConnected = deviceConnected;
    }
    if (deviceConnected && !oldDeviceConnected) {
        oldDeviceConnected = deviceConnected;
        Serial.println("BLE Device connected");
    }
}

void checkEmergencyButton() {
    bool reading = digitalRead(EMERGENCY_BUTTON_PIN) == LOW;

    if (reading != lastEmergencyButtonReading) {
        lastEmergencyButtonPress = millis();
    }

    if ((millis() - lastEmergencyButtonPress) > BUTTON_DEBOUNCE_TIME) {
        if (reading != emergencyButtonState) {
            emergencyButtonState = reading;

            if (emergencyButtonState) {
                emergencyStop = true;
                servoLeft.write(90);
                servoRight.write(90);
                Serial.println("EMERGENCY STOP ACTIVATED");

                if (deviceConnected) {
                    pDataCharacteristic->setValue("EMERGENCY_STOP:1");
                    pDataCharacteristic->notify();
                }
            }
        }
    }

    lastEmergencyButtonReading = reading;
}

void checkWaterproofButton() {
    bool reading = digitalRead(WATERPROOF_BUTTON_PIN) == LOW;

    if (reading != lastWaterproofButtonReading) {
        lastWaterproofButtonPress = millis();
    }

    if ((millis() - lastWaterproofButtonPress) > BUTTON_DEBOUNCE_TIME) {
        if (reading != waterproofButtonState) {
            waterproofButtonState = reading;

            if (waterproofButtonState) {
                stabilizationEnabled = !stabilizationEnabled;
                preferences.putBool("stabilizationEnabled", stabilizationEnabled);
                Serial.printf("Stabilization toggled: %s\n", stabilizationEnabled ? "ON" : "OFF");

                if (deviceConnected) {
                    String status = "STABILIZATION:" + String(stabilizationEnabled ? "1" : "0");
                    pDataCharacteristic->setValue(status.c_str());
                    pDataCharacteristic->notify();
                }
            }
        }
    }

    lastWaterproofButtonReading = reading;
}

void updateIMU() {
    int16_t ax, ay, az, gx, gy, gz;
    mpu.getMotion6(&ax, &ay, &az, &gx, &gy, &gz);

    // Convert to angles (simplified calculation)
    roll = atan2(ay, az) * 180 / PI;
    pitch = atan2(-ax, sqrt(ay * ay + az * az)) * 180 / PI;

    // Apply low-pass filter
    static float rollFiltered = 0, pitchFiltered = 0;
    float alpha = 0.1;
    rollFiltered = alpha * roll + (1 - alpha) * rollFiltered;
    pitchFiltered = alpha * pitch + (1 - alpha) * pitchFiltered;

    roll = rollFiltered;
    pitch = pitchFiltered;
}

void updatePID() {
    if (emergencyStop || !stabilizationEnabled) {
        if (!stabilizationEnabled) {
            servoLeft.write(90);
            servoRight.write(90);
        }
        return;
    }

    // Calculate errors
    rollError = 0 - roll;  // Target is 0 degrees (level)
    pitchError = 0 - pitch;

    // Integral terms
    rollIntegral += rollError * (1.0 / PID_UPDATE_RATE);
    pitchIntegral += pitchError * (1.0 / PID_UPDATE_RATE);

    // Constrain integral terms to prevent windup
    rollIntegral = constrain(rollIntegral, -10, 10);
    pitchIntegral = constrain(pitchIntegral, -10, 10);

    // Derivative terms
    float rollDerivative = (rollError - rollPrevError) * PID_UPDATE_RATE;
    float pitchDerivative = (pitchError - pitchPrevError) * PID_UPDATE_RATE;

    // PID outputs
    float rollOutput = Kp * rollError + Ki * rollIntegral + Kd * rollDerivative;
    float pitchOutput = Kp * pitchError + Ki * pitchIntegral + Kd * pitchDerivative;

    // Update previous errors
    rollPrevError = rollError;
    pitchPrevError = pitchError;

    // Constrain outputs
    rollOutput = constrain(rollOutput, -MAX_SERVO_ANGLE, MAX_SERVO_ANGLE);
    pitchOutput = constrain(pitchOutput, -MAX_SERVO_ANGLE, MAX_SERVO_ANGLE);

    // Apply to servos (differential steering for stabilization)
    int leftServoAngle = 90 + rollOutput - pitchOutput;
    int rightServoAngle = 90 - rollOutput - pitchOutput;

    leftServoAngle = constrain(leftServoAngle, 90 - MAX_SERVO_ANGLE, 90 + MAX_SERVO_ANGLE);
    rightServoAngle = constrain(rightServoAngle, 90 - MAX_SERVO_ANGLE, 90 + MAX_SERVO_ANGLE);

    servoLeft.write(leftServoAngle);
    servoRight.write(rightServoAngle);
}

void checkBattery() {
    // Read battery voltage divider
    int adcValue = analogRead(BATTERY_VOLTAGE_PIN);
    float rawVoltage = (adcValue / 4095.0) * 3.3;

    // Detect battery type based on voltage range
    if (rawVoltage > 2.5) {
        batteryType = 0;  // LiPo (3.7V nominal, ~4.2V max)
        batteryVoltage = rawVoltage * 2;  // Assuming 1:1 voltage divider
    } else {
        // Check battery type pin for drill batteries
        int typeReading = analogRead(BATTERY_TYPE_PIN);
        if (typeReading > 3000) {
            batteryType = 2;  // 20V drill battery
            batteryVoltage = rawVoltage * 6;  // Assuming appropriate divider ratio
        } else {
            batteryType = 1;  // 18V drill battery
            batteryVoltage = rawVoltage * 5.4;  // Assuming appropriate divider ratio
        }
    }

    // Check low battery conditions
    float lowVoltageThreshold;
    switch (batteryType) {
        case 0: lowVoltageThreshold = LI_PO_LOW_VOLTAGE; break;
        case 1: lowVoltageThreshold = DRILL_18V_LOW_VOLTAGE; break;
        case 2: lowVoltageThreshold = DRILL_20V_LOW_VOLTAGE; break;
        default: lowVoltageThreshold = LI_PO_LOW_VOLTAGE; break;
    }

    if (batteryVoltage < lowVoltageThreshold) {
        Serial.printf("LOW BATTERY WARNING: %.2fV (Type: %d)\n", batteryVoltage, batteryType);
        emergencyStop = true;

        if (deviceConnected) {
            String warning = "LOW_BATTERY:" + String(batteryVoltage, 2) + ",TYPE:" + String(batteryType);
            pDataCharacteristic->setValue(warning.c_str());
            pDataCharacteristic->notify();
        }
    }
}

void sendBLEData() {
    if (!deviceConnected) return;

    String data = "ROLL:" + String(roll, 2) +
                  ",PITCH:" + String(pitch, 2) +
                  ",BATTERY:" + String(batteryVoltage, 2) +
                  ",BATTERY_TYPE:" + String(batteryType) +
                  ",STABILIZATION:" + String(stabilizationEnabled ? 1 : 0) +
                  ",EMERGENCY:" + String(emergencyStop ? 1 : 0);

    pDataCharacteristic->setValue(data.c_str());
    pDataCharacteristic->notify();
}

void processCommand(String command) {
    Serial.println("Received command: " + command);

    if (command.startsWith("SET_KP:")) {
        Kp = command.substring(7).toFloat();
        preferences.putFloat("Kp", Kp);
        Serial.printf("Kp set to: %.2f\n", Kp);
    } else if (command.startsWith("SET_KI:")) {
        Ki = command.substring(7).toFloat();
        preferences.putFloat("Ki", Ki);
        Serial.printf("Ki set to: %.2f\n", Ki);
    } else if (command.startsWith("SET_KD:")) {
        Kd = command.substring(7).toFloat();
        preferences.putFloat("Kd", Kd);
        Serial.printf("Kd set to: %.2f\n", Kd);
    } else if (command == "STABILIZATION_ON") {
        stabilizationEnabled = true;
        preferences.putBool("stabilizationEnabled", true);
        Serial.println("Stabilization enabled");
    } else if (command == "STABILIZATION_OFF") {
        stabilizationEnabled = false;
        preferences.putBool("stabilizationEnabled", false);
        Serial.println("Stabilization disabled");
    } else if (command == "EMERGENCY_STOP") {
        emergencyStop = true;
        servoLeft.write(90);
        servoRight.write(90);
        Serial.println("Emergency stop activated");
    } else if (command == "RESET_EMERGENCY") {
        emergencyStop = false;
        Serial.println("Emergency stop reset");
    } else if (command == "GET_STATUS") {
        // Status will be sent in next BLE update
        Serial.println("Status request received");
    }
}