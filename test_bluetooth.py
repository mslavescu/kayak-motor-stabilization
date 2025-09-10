#!/usr/bin/env python3
"""
Bluetooth Testing Script for Kayak Stabilization System
This script helps test the Bluetooth communication between ESP32 and host computer.
"""

import serial
import time
import sys

class BluetoothTester:
    def __init__(self, port='/dev/ttyUSB0', baudrate=115200):
        self.port = port
        self.baudrate = baudrate
        self.serial_conn = None

    def connect(self):
        """Establish serial connection to ESP32"""
        try:
            self.serial_conn = serial.Serial(self.port, self.baudrate, timeout=1)
            time.sleep(2)  # Wait for connection to establish
            print(f"Connected to {self.port} at {self.baudrate} baud")
            return True
        except serial.SerialException as e:
            print(f"Failed to connect: {e}")
            return False

    def disconnect(self):
        """Close serial connection"""
        if self.serial_conn and self.serial_conn.is_open:
            self.serial_conn.close()
            print("Disconnected")

    def send_command(self, command):
        """Send command to ESP32"""
        if self.serial_conn and self.serial_conn.is_open:
            try:
                self.serial_conn.write((command + '\n').encode())
                print(f"Sent: {command}")
                return True
            except serial.SerialException as e:
                print(f"Send failed: {e}")
                return False
        else:
            print("Not connected")
            return False

    def read_response(self, timeout=1):
        """Read response from ESP32"""
        if self.serial_conn and self.serial_conn.is_open:
            try:
                start_time = time.time()
                response = ""
                while time.time() - start_time < timeout:
                    if self.serial_conn.in_waiting > 0:
                        data = self.serial_conn.read(self.serial_conn.in_waiting).decode()
                        response += data
                        if '\n' in data:
                            break
                    time.sleep(0.1)
                return response.strip()
            except serial.SerialException as e:
                print(f"Read failed: {e}")
                return None
        else:
            print("Not connected")
            return None

    def test_pid_parameters(self):
        """Test PID parameter setting and retrieval"""
        print("\n=== Testing PID Parameters ===")

        # Test setting Kp
        self.send_command("SET_KP:2.5")
        time.sleep(0.5)
        response = self.read_response()
        print(f"Kp response: {response}")

        # Test setting Ki
        self.send_command("SET_KI:0.15")
        time.sleep(0.5)
        response = self.read_response()
        print(f"Ki response: {response}")

        # Test setting Kd
        self.send_command("SET_KD:0.8")
        time.sleep(0.5)
        response = self.read_response()
        print(f"Kd response: {response}")

    def test_status_request(self):
        """Test status request"""
        print("\n=== Testing Status Request ===")
        self.send_command("GET_STATUS")
        time.sleep(0.5)
        response = self.read_response()
        print(f"Status: {response}")

    def monitor_data(self, duration=10):
        """Monitor real-time data from ESP32"""
        print(f"\n=== Monitoring Data for {duration} seconds ===")
        print("Press Ctrl+C to stop monitoring")

        start_time = time.time()
        try:
            while time.time() - start_time < duration:
                response = self.read_response(0.1)
                if response:
                    print(f"Data: {response}")
        except KeyboardInterrupt:
            print("\nMonitoring stopped by user")

    def parse_sensor_data(self, data_string):
        """Parse sensor data string into dictionary"""
        data = {}
        try:
            parts = data_string.split(',')
            for part in parts:
                if ':' in part:
                    key, value = part.split(':', 1)
                    data[key] = value
            return data
        except:
            return {}

def main():
    print("ESP32 Kayak Stabilization System - Bluetooth Tester")
    print("=" * 50)

    # Default port for Linux, adjust for your system
    default_port = '/dev/ttyUSB0' if sys.platform.startswith('linux') else 'COM3'

    tester = BluetoothTester(port=default_port)

    if not tester.connect():
        print("Failed to connect. Please check:")
        print("1. ESP32 is connected and powered")
        print("2. Correct serial port")
        print("3. ESP32 is running the kayak_stabilizer.ino sketch")
        sys.exit(1)

    try:
        while True:
            print("\nAvailable tests:")
            print("1. Test PID parameters")
            print("2. Test status request")
            print("3. Monitor real-time data")
            print("4. Parse sample data")
            print("5. Exit")

            choice = input("Select test (1-5): ").strip()

            if choice == '1':
                tester.test_pid_parameters()
            elif choice == '2':
                tester.test_status_request()
            elif choice == '3':
                duration = input("Monitoring duration (seconds): ").strip()
                try:
                    duration = int(duration)
                    tester.monitor_data(duration)
                except ValueError:
                    print("Invalid duration, using 10 seconds")
                    tester.monitor_data(10)
            elif choice == '4':
                sample_data = input("Enter sample data string: ").strip()
                parsed = tester.parse_sensor_data(sample_data)
                print(f"Parsed data: {parsed}")
            elif choice == '5':
                break
            else:
                print("Invalid choice")

    except KeyboardInterrupt:
        print("\nInterrupted by user")

    finally:
        tester.disconnect()

if __name__ == "__main__":
    main()