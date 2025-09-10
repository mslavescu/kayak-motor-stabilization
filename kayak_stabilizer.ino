#include <Wire.h>
#include <MPU6050.h>
#include <ESP32Servo.h>
#include <BluetoothSerial.h>
#include <Preferences.h>

// Pin definitions
#define SERVO_LEFT_PIN 12
#define SERVO_RIGHT_PIN 13
#define EMERGENCY_BUTTON_PIN 14
#define BATTERY_VOLTAGE_PIN 34

// System constants
#define IMU_UPDATE_RATE 100  // Hz
#define PID_UPDATE_RATE 50   // Hz
#define MAX_SERVO_ANGLE 30   // degrees
#define BATTERY_LOW_VOLTAGE 3.3  // V

// PID parameters (adjustable via app)
float Kp = 2.0;
float Ki = 0.1;
float Kd = 0.5;

// Global variables
MPU6050 mpu;
Servo servoLeft, servoRight;
BluetoothSerial SerialBT;
Preferences preferences;

float roll, pitch, yaw;
float rollError, pitchError;
float rollIntegral = 0, pitchIntegral = 0;
float rollPrevError = 0, pitchPrevError = 0;
unsigned long lastImuUpdate = 0;
unsigned long lastPidUpdate = 0;
bool emergencyStop = false;
float batteryVoltage = 0;

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

  // Initialize Bluetooth
  SerialBT.begin("KayakStabilizer");
  Serial.println("Bluetooth started");

  // Initialize preferences for storing settings
  preferences.begin("stabilizer", false);

  // Load PID parameters from preferences
  Kp = preferences.getFloat("Kp", 2.0);
  Ki = preferences.getFloat("Ki", 0.1);
  Kd = preferences.getFloat("Kd", 0.5);

  // Setup emergency button
  pinMode(EMERGENCY_BUTTON_PIN, INPUT_PULLUP);

  Serial.println("Kayak Stabilization System Initialized");
}

void loop() {
  unsigned long currentTime = millis();

  // Check emergency stop
  if (digitalRead(EMERGENCY_BUTTON_PIN) == LOW) {
    emergencyStop = true;
    servoLeft.write(90);
    servoRight.write(90);
    SerialBT.println("EMERGENCY STOP ACTIVATED");
  }

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

  // Check battery voltage
  checkBattery();

  // Handle Bluetooth commands
  handleBluetooth();

  delay(10);  // Small delay to prevent overwhelming the processor
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
  if (emergencyStop) return;

  // Calculate errors
  rollError = 0 - roll;  // Target is 0 degrees (level)
  pitchError = 0 - pitch;

  // Integral terms
  rollIntegral += rollError * (1.0 / PID_UPDATE_RATE);
  pitchIntegral += pitchError * (1.0 / PID_UPDATE_RATE);

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

  // Send status to app
  SerialBT.printf("ROLL:%.2f,PITCH:%.2f,L_SERVO:%d,R_SERVO:%d\n", roll, pitch, leftServoAngle, rightServoAngle);
}

void checkBattery() {
  // Read battery voltage (assuming voltage divider)
  int adcValue = analogRead(BATTERY_VOLTAGE_PIN);
  batteryVoltage = (adcValue / 4095.0) * 3.3 * 2;  // Adjust multiplier based on divider ratio

  if (batteryVoltage < BATTERY_LOW_VOLTAGE) {
    SerialBT.println("LOW BATTERY WARNING");
    emergencyStop = true;
  }
}

void handleBluetooth() {
  if (SerialBT.available()) {
    String command = SerialBT.readStringUntil('\n');
    command.trim();

    if (command.startsWith("SET_KP:")) {
      Kp = command.substring(7).toFloat();
      preferences.putFloat("Kp", Kp);
      SerialBT.printf("Kp set to: %.2f\n", Kp);
    } else if (command.startsWith("SET_KI:")) {
      Ki = command.substring(7).toFloat();
      preferences.putFloat("Ki", Ki);
      SerialBT.printf("Ki set to: %.2f\n", Ki);
    } else if (command.startsWith("SET_KD:")) {
      Kd = command.substring(7).toFloat();
      preferences.putFloat("Kd", Kd);
      SerialBT.printf("Kd set to: %.2f\n", Kd);
    } else if (command == "RESET_EMERGENCY") {
      emergencyStop = false;
      SerialBT.println("Emergency stop reset");
    } else if (command == "GET_STATUS") {
      SerialBT.printf("STATUS:ROLL=%.2f,PITCH=%.2f,BATTERY=%.2fV,EMERGENCY=%d\n",
                      roll, pitch, batteryVoltage, emergencyStop);
    }
  }
}