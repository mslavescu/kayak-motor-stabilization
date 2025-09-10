# System Diagrams and Schematics
## Complete Technical Documentation for Kayak Stabilization System

## Table of Contents
1. [System Block Diagrams](#system-block-diagrams)
2. [Electrical Schematics](#electrical-schematics)
3. [Wiring Diagrams](#wiring-diagrams)
4. [Mechanical Drawings](#mechanical-drawings)
5. [Component Layout Diagrams](#component-layout-diagrams)
6. [Flow Charts](#flow-charts)

---

## System Block Diagrams

### Complete System Architecture
```
┌─────────────────────────────────────────────────────────────────┐
│                    KAYAK STABILIZATION SYSTEM                    │
│                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────┐  │
│  │   SMARTPHONE    │    │     ESP32       │    │   MOTORS    │  │
│  │   (ANDROID)     │◄──►│   CONTROLLER    │◄──►│  (SERVO/    │  │
│  │                 │    │                 │    │   STEPPER/   │  │
│  │ • BLE Control   │    │ • IMU Sensor    │    │   BRUSHLESS) │  │
│  │ • PID Tuning    │    │ • Motor Control  │    │             │  │
│  │ • Status Display│    │ • BLE Server     │    │             │  │
│  │ • Emergency Stop│    │ • Battery Monitor│    │             │  │
│  └─────────────────┘    └─────────────────┘    └─────────────┘  │
│           │                       │                    │        │
│           │                       │                    │        │
│           ▼                       ▼                    ▼        │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────┐  │
│  │   BLE RADIO     │    │   SENSORS       │    │   ACTUATORS │  │
│  │   (2.4GHz)      │    │                 │    │             │  │
│  │ • 10m Range     │    │ • MPU6050 IMU   │    │ • PWM Output │  │
│  │ • Low Latency   │    │ • Battery Sense │    │ • Step/Dir   │  │
│  │ • Secure Pairing│    │ • Button Input  │    │ • ESC Control│  │
│  └─────────────────┘    └─────────────────┘    └─────────────┘  │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                 POWER MANAGEMENT SYSTEM                     │  │
│  │                                                             │  │
│  │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐       │  │
│  │  │  BATTERY    │    │ REGULATORS  │    │ PROTECTION │       │  │
│  │  │  (LiPo/     │───►│  (DC-DC)    │───►│  (FUSES/   │       │  │
│  │  │   Drill)    │    │             │    │   ESD)      │       │  │
│  │  │ • Auto Type │    │ • 18V→5V    │    │ • Overload  │       │  │
│  │  │ • Monitoring │    │ • 5V→3.3V  │    │ • Short Ckt │       │  │
│  │  └─────────────┘    └─────────────┘    └─────────────┘       │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                 MECHANICAL SYSTEM                           │  │
│  │                                                             │  │
│  │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐       │  │
│  │  │  MOUNTS     │    │ ENCLOSURE   │    │ KAYAK HULL │       │  │
│  │  │  (3D PRINT) │    │ (IP67)      │    │             │       │  │
│  │  │ • Motor Base │    │ • ABS/PLA   │    │ • Adhesive  │       │  │
│  │  │ • Cable Mgmt │    │ • Waterproof │    │ • Through   │       │  │
│  │  └─────────────┘    └─────────────┘    └─────────────┘       │  │
│  └─────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### BLE Communication Architecture
```
┌─────────────────┐                    ┌─────────────────┐
│   ANDROID APP   │                    │     ESP32       │
│                 │                    │   (SERVER)      │
├─────────────────┤                    ├─────────────────┤
│ • Device Scan   │◄──────────────────►│ • Advertising   │
│ • GATT Client   │                    │ • GATT Server   │
│ • Service Disc. │                    │ • Characteristics│
│ • Notifications │                    │ • Callbacks     │
└─────────────────┘                    └─────────────────┘
         │                                       │
         │                                       │
    ┌────▼────┐                             ┌────▼────┐
    │SERVICE  │                             │SERVICE  │
    │UUID:    │                             │UUID:    │
    │4fafc201-│                             │4fafc201-│
    │1fb5-459e│                             │1fb5-459e│
    │8fcc-    │                             │8fcc-    │
    │c5c9c3319│                             │c5c9c3319│
    │14b      │                             │14b      │
    └────┬────┘                             └────┬────┘
         │                                       │
    ┌────▼─────────────────────────┐    ┌────▼─────────────────────────┐
    │CHARACTERISTICS               │    │CHARACTERISTICS               │
    ├──────────────────────────────┤    ├──────────────────────────────┤
    │• Data (Notify)               │    │• Data (Notify)               │
    │  UUID: beb5483e-36e1-4688-   │    │  UUID: beb5483e-36e1-4688-   │
    │       b7f5-ea07361b26a8       │    │       b7f5-ea07361b26a8       │
    │• Command (Write)             │    │• Command (Write)             │
    │  UUID: beb5483f-36e1-4688-   │    │  UUID: beb5483f-36e1-4688-   │
    │       b7f5-ea07361b26a8       │    │       b7f5-ea07361b26a8       │
    └──────────────────────────────┘    └──────────────────────────────┘
```

---

## Electrical Schematics

### ESP32 Power Supply and Regulation
```
┌─────────────────────────────────────────────────────────────────┐
│                    ESP32 POWER MANAGEMENT                        │
│                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────┐  │
│  │   BATTERY       │    │   REGULATOR     │    │   FILTER    │  │
│  │   INPUT         │───►│   (DC-DC)       │───►│   CAPS      │  │
│  │  3.7V-24V       │    │                 │    │             │  │
│  └─────────────────┘    └─────────────────┘    └─────────────┘  │
│           │                       │                    │        │
│           │                       │                    │        │
│           ▼                       ▼                    ▼        │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────┐  │
│  │   FUSE          │    │   SWITCHING     │    │   OUTPUT    │  │
│  │   PROTECTION    │    │   CONVERTER     │    │   3.3V      │  │
│  │   5A FAST BLOW  │    │   EFFICIENCY    │    │   REGULATED │  │
│  │                 │    │   >85%          │    │             │  │
│  └─────────────────┘    └─────────────────┘    └─────────────┘  │
│                                                                 │
│  Power Path: Battery → Fuse → Regulator → Filter → ESP32 VIN    │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                 VOLTAGE MONITORING                          │  │
│  │                                                             │  │
│  │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐       │  │
│  │  │  VOLTAGE    │    │  DIVIDER    │    │   ADC       │       │  │
│  │  │  INPUT      │───►│  NETWORK    │───►│   INPUT     │       │  │
│  │  │  3.7-24V    │    │  R1=10k     │    │  GPIO 34    │       │  │
│  │  │             │    │  R2=10k     │    │  12-bit     │       │  │
│  │  └─────────────┘    └─────────────┘    └─────────────┘       │  │
│  └─────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Motor Control Circuits

#### Servo Motor Control
```
┌─────────────────────────────────────────────────────────────────┐
│                    SERVO MOTOR CONTROL                          │
│                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────┐  │
│  │   ESP32 PWM     │    │   SIGNAL        │    │   SERVO     │  │
│  │   OUTPUT        │───►│   CONDITIONING │───►│   MOTOR     │  │
│  │  GPIO 12/13     │    │                 │    │  MG90S      │  │
│  └─────────────────┘    └─────────────────┘    └─────────────┘  │
│           │                       │                    │        │
│           │                       │                    │        │
│           ▼                       ▼                    ▼        │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────┐  │
│  │   PWM SIGNAL    │    │   POWER         │    │   POSITION  │  │
│  │   50Hz, 1-2ms   │    │   SUPPLY        │    │   FEEDBACK  │  │
│  │   DUTY CYCLE    │    │   4.8-6V        │    │   POT        │  │
│  └─────────────────┘    └─────────────────┘    └─────────────┘  │
│                                                                 │
│  Signal: 1ms = -90°, 1.5ms = 0°, 2ms = +90°                    │
│  Power: 4.8V nominal, 6V max, 500mA stall current              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

#### Stepper Motor Control (NEMA 17/23)
```
┌─────────────────────────────────────────────────────────────────┐
│                 STEPPER MOTOR CONTROL                           │
│                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────┐  │
│  │   ESP32 GPIO    │    │   DRIVER        │    │   MOTOR     │  │
│  │   SIGNALS       │───►│   (A4988/DM542)│───►│  NEMA 17/23 │  │
│  │  STEP/DIR/EN    │    │                 │    │             │  │
│  └─────────────────┘    └─────────────────┘    └─────────────┘  │
│           │                       │                    │        │
│           │                       ▼                    ▼        │
│           │            ┌─────────────────┐    ┌─────────────┐  │
│           │            │   MICROSTEPPING │    │   COILS     │  │
│           │            │   MS1/MS2/MS3   │    │   A+/A-/     │  │
│           │            │   CONFIG        │    │   B+/B-     │  │
│           └────────────┼─────────────────┼────┼─────────────┘  │
│                        │                 │    │                │
│            ┌───────────▼─────────────────▼────▼─────────────┐  │
│            │              POWER SUPPLY                       │  │
│            │                                                 │  │
│            │  ┌─────────────┐    ┌─────────────┐             │  │
│            │  │   VMOT      │    │   LOGIC     │             │  │
│            │  │   8-35V     │    │   3.3-5V    │             │  │
│            │  │   HIGH      │    │   LOW       │             │  │
│            │  │   CURRENT   │    │   CURRENT   │             │  │
│            │  └─────────────┘    └─────────────┘             │  │
│            └─────────────────────────────────────────────────┘  │
│                                                                 │
│  Step Sequence: A+ A- B+ B- (Full Step)                         │
│  Current: Set VREF = Imax × 8 × Rsense                          │
│  Microstepping: 1/16 for smooth motion                          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

#### Brushless DC Motor Control
```
┌─────────────────────────────────────────────────────────────────┐
│                 BRUSHLESS DC MOTOR CONTROL                      │
│                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────┐  │
│  │   ESP32 PWM     │    │   ELECTRONIC    │    │   BRUSHLESS │  │
│  │   SIGNAL        │───►│   SPEED CTRL    │───►│   MOTOR     │  │
│  │  SERVO OUTPUT   │    │   (ESC)         │    │  2212-KV920 │  │
│  └─────────────────┘    └─────────────────┘    └─────────────┘  │
│           │                       │                    │        │
│           │                       │                    │        │
│           ▼                       ▼                    ▼        │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────┐  │
│  │   PWM INPUT     │    │   3-PHASE       │    │   ROTOR     │  │
│  │   50Hz, 1-2ms   │    │   OUTPUT        │    │   POSITION  │  │
│  │   STANDARD      │    │   6-STEP        │    │   SENSORS   │  │
│  └─────────────────┘    └─────────────────┘    └─────────────┘  │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                 ESC INTERNAL ARCHITECTURE                   │  │
│  │                                                             │  │
│  │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐       │  │
│  │  │  BEC        │    │  MOSFET     │    │  MCU        │       │  │
│  │  │  REGULATOR  │    │  DRIVERS    │    │  CONTROLLER │       │  │
│  │  │  5V/2A      │    │  30A MAX    │    │  ATMEGA     │       │  │
│  │  │  OUTPUT     │    │  N-CHANNEL  │    │  8-BIT      │       │  │
│  │  └─────────────┘    └─────────────┘    └─────────────┘       │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                 │
│  PWM: 1ms = Stop, 1.5ms = 50%, 2ms = Full Speed                 │
│  Power: 2-4S LiPo (7.4-14.8V), 30A continuous                   │
│  Protection: Low voltage cutoff, overcurrent, thermal          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Wiring Diagrams

### Complete System Wiring
```
┌─────────────────────────────────────────────────────────────────┐
│                    COMPLETE SYSTEM WIRING                       │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                        ESP32 BOARD                          │  │
│  │  ┌─────────────────────────────────────────────────────────┐  │
│  │  │  PIN   | FUNCTION          | CONNECTION                 │  │
│  │  ├─────────────────────────────────────────────────────────┤  │
│  │  │  VIN   | POWER INPUT       | REGULATOR OUTPUT           │  │
│  │  │  GND   | GROUND            | COMMON GROUND              │  │
│  │  │  3.3V  | POWER OUTPUT      | IMU POWER                  │  │
│  │  │  GPIO 21| I2C SDA          | MPU6050 SDA                │  │
│  │  │  GPIO 22| I2C SCL          | MPU6050 SCL                │  │
│  │  │  GPIO 12| SERVO 1 SIGNAL   | SERVO 1 CONTROL            │  │
│  │  │  GPIO 13| SERVO 2 SIGNAL   | SERVO 2 CONTROL            │  │
│  │  │  GPIO 14| EMERGENCY BUTTON | WATERPROOF BUTTON          │  │
│  │  │  GPIO 15| WATERPROOF BTN   | STABILIZATION TOGGLE       │  │
│  │  │  GPIO 25| STEPPER STEP     | A4988 STEP                 │  │
│  │  │  GPIO 26| STEPPER DIR      | A4988 DIR                  │  │
│  │  │  GPIO 27| STEPPER ENABLE   | A4988 ENABLE               │  │
│  │  │  GPIO 34| BATTERY VOLTAGE  | VOLTAGE DIVIDER            │  │
│  │  │  GPIO 35| BATTERY TYPE     | TYPE DETECTION             │  │
│  │  └─────────────────────────────────────────────────────────┘  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                    MOTOR WIRING OPTIONS                      │  │
│  │                                                             │  │
│  │  ┌─────────────────┐    ┌─────────────────┐    ┌─────────┐  │  │
│  │  │   SERVO MOTORS  │    │  STEPPER MOTORS │    │ BRUSHLESS│  │
│  │  │                 │    │                 │    │  MOTORS  │  │
│  │  │ • Signal: PWM   │    │ • STEP: GPIO25  │    │ • Signal │  │
│  │  │ • Power: 5V     │    │ • DIR: GPIO26   │    │ • Power  │  │
│  │  │ • Ground: GND   │    │ • ENABLE: GPIO27│    │ • BEC 5V │  │
│  │  │                 │    │ • VMOT: 12V     │    │          │  │
│  │  │                 │    │ • GND: COMMON   │    │          │  │
│  │  └─────────────────┘    └─────────────────┘    └─────────┘  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                    POWER DISTRIBUTION                        │  │
│  │                                                             │  │
│  │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐       │  │
│  │  │  BATTERY    │    │ REGULATOR 1 │    │ REGULATOR 2 │       │  │
│  │  │  INPUT      │───►│ 18V→5V     │───►│ 5V→3.3V    │       │  │
│  │  │ 3.7-24V     │    │ DC-DC       │    │ DC-DC       │       │  │
│  │  │             │    │             │    │             │       │  │
│  │  └─────────────┘    └─────────────┘    └─────────────┘       │  │
│  └─────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Sensor and Control Wiring
```
┌─────────────────────────────────────────────────────────────────┐
│                 SENSORS AND CONTROL WIRING                      │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                    MPU6050 IMU WIRING                        │  │
│  │  ┌─────────────────────────────────────────────────────────┐  │
│  │  │  MPU6050 PIN | ESP32 PIN       | FUNCTION               │  │
│  │  ├─────────────────────────────────────────────────────────┤  │
│  │  │  VCC         | 3.3V            | POWER                  │  │
│  │  │  GND         | GND             | GROUND                 │  │
│  │  │  SDA         | GPIO 21         | I2C DATA               │  │
│  │  │  SCL         | GPIO 22         | I2C CLOCK              │  │
│  │  │  INT         | Not Connected   | INTERRUPT (Optional)   │  │
│  │  └─────────────────────────────────────────────────────────┘  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                 VOLTAGE MONITORING CIRCUIT                   │  │
│  │                                                             │  │
│  │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐       │  │
│  │  │  BATTERY    │    │  RESISTOR   │    │  ESP32 ADC  │       │  │
│  │  │  POSITIVE   │───►│  DIVIDER    │───►│  INPUT      │       │  │
│  │  │  3.7-24V    │    │  R1=10k     │    │  GPIO 34    │       │
│  │  │             │    │  R2=10k     │    │             │       │
│  │  │             │    │  TO GND     │    │             │       │
│  │  └─────────────┘    └─────────────┘    └─────────────┘       │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                 BATTERY TYPE DETECTION                       │  │
│  │                                                             │  │
│  │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐       │  │
│  │  │  BATTERY    │    │  RESISTOR   │    │  ESP32 ADC  │       │  │
│  │  │  POSITIVE   │───►│  DIVIDER    │───►│  INPUT      │       │
│  │  │  3.7-24V    │    │  R3=22k     │    │  GPIO 35    │       │
│  │  │             │    │  R4=10k     │    │             │       │
│  │  │             │    │  TO GND     │    │             │       │
│  │  └─────────────┘    └─────────────┘    └─────────────┘       │
│  └─────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Mechanical Drawings

### Motor Mount Base Dimensions
```
┌─────────────────────────────────────────────────────────────────┐
│                 MOTOR MOUNT BASE DIMENSIONS                     │
│                                                                 │
│  TOP VIEW:                                                      │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                                                            │  │
│  │  ◯ M5 HULL MOUNT          ◯ M5 HULL MOUNT                 │  │
│  │     (15mm from edge)         (65mm from edge)              │  │
│  │                                                            │  │
│  │                                                            │  │
│  │                 ◯ MOTOR SHAFT                               │  │
│  │                    (40mm from left)                         │  │
│  │                                                            │  │
│  │  ◯ M3 MOTOR MOUNT        ◯ M3 MOTOR MOUNT                 │  │
│  │     (25,25)                  (55,25)                       │  │
│  │                                                            │  │
│  │  ◯ M3 MOTOR MOUNT        ◯ M3 MOTOR MOUNT                 │  │
│  │     (25,55)                  (55,55)                       │  │
│  │                                                            │  │
│  └─────────────────────────────────────────────────────────────┘  │
│           80mm                                                  │
│                                                                 │
│  SIDE VIEW:                                                     │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  ┌─────────────────────────────────────────────────────────┐ │  │
│  │  │                                                         │ │  │
│  │  │  3mm BASE PLATE                                        │ │  │
│  │  │                                                         │ │  │
│  │  └─────────────────────────────────────────────────────────┘ │  │
│  │                                                               │  │
│  │  37mm TOTAL HEIGHT                                           │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                 │
│  DIMENSIONS:                                                    │
│  • Length: 80mm                                                │
│  • Width: 60mm                                                 │
│  • Height: 40mm                                                │
│  • Motor Pattern: 31mm (NEMA 17)                               │
│  • Hull Holes: M5, 50mm spacing                                │
│  • Material: ABS or PLA                                        │
│  • Wall Thickness: 3mm                                         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Enclosure Mounting Bracket
```
┌─────────────────────────────────────────────────────────────────┐
│              ENCLOSURE MOUNTING BRACKET DIMENSIONS              │
│                                                                 │
│  TOP VIEW:                                                      │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                                                            │  │
│  │  ◯ M4 ENCLOSURE         ◯ M4 ENCLOSURE                     │  │
│  │     (20mm from edge)       (100mm from edge)               │  │
│  │                                                            │  │
│  │                                                            │  │
│  │                                                            │  │
│  │                                                            │  │
│  │  ◯ M5 HULL MOUNT        ◯ M5 HULL MOUNT                    │  │
│  │     (10,25)                 (10,75)                        │  │
│  │                                                            │  │
│  │  ◯ M5 HULL MOUNT        ◯ M5 HULL MOUNT                    │  │
│  │     (110,25)                (110,75)                       │  │
│  │                                                            │  │
│  └─────────────────────────────────────────────────────────────┘  │
│           120mm                                                 │
│                                                                 │
│  SIDE VIEW:                                                     │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  ┌─────────────────────────────────────────────────────────┐ │  │
│  │  │                                                         │ │  │
│  │  │  3mm BASE PLATE                                        │ │  │
│  │  │                                                         │ │  │
│  │  └─────────────────────────────────────────────────────────┘ │  │
│  │                                                               │  │
│  │  30mm TOTAL HEIGHT                                          │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                 │
│  DIMENSIONS:                                                    │
│  • Length: 120mm                                               │
│  • Width: 40mm                                                 │
│  • Height: 30mm                                                │
│  • Enclosure Holes: M4, 80mm spacing                           │
│  • Hull Holes: M5, 100mm spacing                               │
│  • Material: ABS (weather resistant)                           │
│  • Wall Thickness: 3mm                                         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Component Layout Diagrams

### Electronics Enclosure Layout
```
┌─────────────────────────────────────────────────────────────────┐
│                ELECTRONICS ENCLOSURE LAYOUT                     │
│                                                                 │
│  INTERNAL LAYOUT (TOP VIEW):                                    │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │  │
│  │  │   ESP32     │  │   MPU6050   │  │  REGULATOR  │         │  │
│  │  │ CONTROLLER  │  │     IMU     │  │   DC-DC     │         │  │
│  │  │             │  │             │  │             │         │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘         │  │
│  │                                                             │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │  │
│  │  │  MOTOR      │  │  MOTOR      │  │ WATERPROOF  │         │  │
│  │  │ DRIVER 1    │  │ DRIVER 2    │  │   BUTTON    │         │  │
│  │  │             │  │             │  │             │         │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘         │  │
│  │                                                             │  │
│  │  ┌─────────────────────────────────────────────────────────┐  │
│  │  │                    BATTERY COMPARTMENT                   │  │
│  │  │                                                         │  │
│  │  └─────────────────────────────────────────────────────────┘  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                 │
│  EXTERNAL CONNECTIONS:                                          │
│  • Power Input (Battery)                                        │
│  • Motor Outputs (2x)                                          │
│  • Antenna (BLE/WiFi)                                          │
│  • Waterproof Button                                           │
│  • Status LED                                                  │
│                                                                 │
│  ENCLOSURE SPECIFICATIONS:                                      │
│  • Size: 100x68x50mm (IP67)                                     │
│  • Material: ABS plastic                                        │
│  • Cable Glands: 4x M12                                        │
│  • Mounting: 4x M4 holes                                       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Kayak Hull Mounting Layout
```
┌─────────────────────────────────────────────────────────────────┐
│                 KAYAK HULL MOUNTING LAYOUT                      │
│                                                                 │
│  TOP VIEW OF KAYAK:                                             │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                                                            │  │
│  │  ◯ MOTOR MOUNT 1          ◯ MOTOR MOUNT 2                 │  │
│  │     (Port Side)              (Starboard Side)              │  │
│  │                                                            │  │
│  │                                                            │  │
│  │                                                            │  │
│  │                                                            │  │
│  │               ◯ ELECTRONICS ENCLOSURE                      │  │
│  │                      (Centerline)                          │  │
│  │                                                            │  │
│  │                                                            │  │
│  │                                                            │  │
│  └─────────────────────────────────────────────────────────────┘  │
│           800mm (Typical kayak width)                           │
│                                                                 │
│  MOUNTING SPECIFICATIONS:                                       │
│  • Motor Spacing: 600mm center-to-center                       │
│  • Hull Position: 300mm aft of cockpit                         │
│  • Enclosure Position: Midships centerline                     │
│  • Adhesive: Marine-grade epoxy                                 │
│  • Fasteners: Stainless steel M5                                │
│                                                                 │
│  ALIGNMENT REQUIREMENTS:                                        │
│  • Motors parallel to waterline                                 │
│  • Equal distance from centerline                               │
│  • Secure mounting to prevent vibration                        │
│  • Cable routing away from propeller                            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Flow Charts

### System Startup Sequence
```
┌─────────────────────────────────────────────────────────────────┐
│                 SYSTEM STARTUP SEQUENCE                         │
│                                                                 │
│  ┌─────────────────┐                                           │
│  │   POWER ON      │                                           │
│  └─────────────────┘                                           │
│           │                                                    │
│           ▼                                                    │
│  ┌─────────────────┐                                           │
│  │   ESP32 BOOT    │                                           │
│  │   SEQUENCE      │                                           │
│  └─────────────────┘                                           │
│           │                                                    │
│           ▼                                                    │
│  ┌─────────────────┐    ┌─────────────────┐                    │
│  │ INITIALIZE I2C │    │ INITIALIZE BLE  │                    │
│  │   BUS           │    │   SERVER        │                    │
│  └─────────────────┘    └─────────────────┘                    │
│           │                       │                           │
│           ▼                       ▼                           │
│  ┌─────────────────┐    ┌─────────────────┐                    │
│  │   IMU TEST      │    │   BLE ADVERTISE │                    │
│  │   CONNECTION    │    │   START         │                    │
│  └─────────────────┘    └─────────────────┘                    │
│           │                       │                           │
│           ▼                       ▼                           │
│  ┌─────────────────┐    ┌─────────────────┐                    │
│  │ MOTOR DRIVER    │    │   WAIT FOR      │                    │
│  │ INITIALIZATION  │    │   CONNECTION    │                    │
│  └─────────────────┘    └─────────────────┘                    │
│           │                       │                           │
│           ▼                       ▼                           │
│  ┌─────────────────┐    ┌─────────────────┐                    │
│  │ CALIBRATE IMU  │    │   BLE CONNECTED  │                    │
│  │   SENSORS       │    │   ESTABLISHED   │                    │
│  └─────────────────┘    └─────────────────┘                    │
│           │                       │                           │
│           ▼                       ▼                           │
│  ┌─────────────────┐    ┌─────────────────┐                    │
│  │ LOAD PID        │    │   START DATA    │                    │
│  │ PARAMETERS      │    │   STREAMING     │                    │
│  └─────────────────┘    └─────────────────┘                    │
│           │                       │                           │
│           ▼                       ▼                           │
│  ┌─────────────────┐    ┌─────────────────┐                    │
│  │ SYSTEM READY    │    │   READY FOR     │                    │
│  │ FOR OPERATION   │    │   COMMANDS      │                    │
│  └─────────────────┘    └─────────────────┘                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### PID Control Loop
```
┌─────────────────────────────────────────────────────────────────┐
│                    PID CONTROL LOOP                             │
│                                                                 │
│  ┌─────────────────┐                                           │
│  │   IMU READ      │                                           │
│  │   SENSORS       │                                           │
│  └─────────────────┘                                           │
│           │                                                    │
│           ▼                                                    │
│  ┌─────────────────┐                                           │
│  │   APPLY LOW     │                                           │
│  │   PASS FILTER   │                                           │
│  └─────────────────┘                                           │
│           │                                                    │
│           ▼                                                    │
│  ┌─────────────────┐    ┌─────────────────┐                    │
│  │ CALCULATE ERROR │    │   CHECK SYSTEM  │                    │
│  │ (TARGET - ACTUAL│    │   STATUS        │                    │
│  └─────────────────┘    └─────────────────┘                    │
│           │                       │                           │
│           ▼                       │                           │
│  ┌─────────────────┐             │                           │
│  │   EMERGENCY     │◄────────────┘                           │
│  │   STOP?         │                                           │
│  └─────────────────┘                                           │
│           │                                                    │
│           ▼                                                    │
│  ┌─────────────────┐                                           │
│  │   STABILIZATION │                                           │
│  │   ENABLED?      │                                           │
│  └─────────────────┘                                           │
│           │                                                    │
│           ▼                                                    │
│  ┌─────────────────┐                                           │
│  │   CALCULATE PID │                                           │
│  │   OUTPUT        │                                           │
│  └─────────────────┘                                           │
│           │                                                    │
│           ▼                                                    │
│  ┌─────────────────┐    ┌─────────────────┐                    │
│  │   APPLY OUTPUT  │    │   CONSTRAIN     │                    │
│  │   TO MOTORS     │    │   LIMITS        │                    │
│  └─────────────────┘    └─────────────────┘                    │
│           │                       │                           │
│           ▼                       ▼                           │
│  ┌─────────────────┐    ┌─────────────────┐                    │
│  │   UPDATE PID    │    │   MOTOR OUTPUT  │                    │
│  │   INTEGRAL      │    │   UPDATED       │                    │
│  └─────────────────┘    └─────────────────┘                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### BLE Communication Flow
```
┌─────────────────────────────────────────────────────────────────┐
│                 BLE COMMUNICATION FLOW                          │
│                                                                 │
│  ┌─────────────────┐                                           │
│  │   ESP32 START   │                                           │
│  │   BLE SERVER    │                                           │
│  └─────────────────┘                                           │
│           │                                                    │
│           ▼                                                    │
│  ┌─────────────────┐                                           │
│  │   START         │                                           │
│  │   ADVERTISING   │                                           │
│  └─────────────────┘                                           │
│           │                                                    │
│           ▼                                                    │
│  ┌─────────────────┐                                           │
│  │   ANDROID APP   │                                           │
│  │   DEVICE SCAN   │                                           │
│  └─────────────────┘                                           │
│           │                                                    │
│           ▼                                                    │
│  ┌─────────────────┐                                           │
│  │   DEVICE FOUND  │                                           │
│  │   "KayakStabilizer"│                                        │
│  └─────────────────┘                                           │
│           │                                                    │
│           ▼                                                    │
│  ┌─────────────────┐                                           │
│  │   GATT CONNECT  │                                           │
│  │   ESTABLISHED   │                                           │
│  └─────────────────┘                                           │
│           │                                                    │
│           ▼                                                    │
│  ┌─────────────────┐    ┌─────────────────┐                    │
│  │   SERVICE       │    │   CHARACTERISTIC│                    │
│  │   DISCOVERY     │    │   DISCOVERY     │                    │
│  └─────────────────┘    └─────────────────┘                    │
│           │                       │                           │
│           ▼                       ▼                           │
│  ┌─────────────────┐    ┌─────────────────┐                    │
│  │   ENABLE        │    │   SUBSCRIBE TO  │                    │
│  │   NOTIFICATIONS │    │   DATA STREAM   │                    │
│  └─────────────────┘    └─────────────────┘                    │
│           │                       │                           │
│           ▼                       ▼                           │
│  ┌─────────────────┐    ┌─────────────────┐                    │
│  │   READY FOR     │    │   DATA FLOW     │                    │
│  │   COMMANDS      │    │   ACTIVE        │                    │
│  └─────────────────┘    └─────────────────┘                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

This comprehensive diagram collection provides all the technical documentation needed to understand, build, and troubleshoot the kayak motor stabilization system. The diagrams cover electrical, mechanical, and software aspects of the system with detailed specifications for each component.