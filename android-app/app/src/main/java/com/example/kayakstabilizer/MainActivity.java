package com.example.kayakstabilizer;

import android.Manifest;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCallback;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattService;
import android.bluetooth.BluetoothManager;
import android.bluetooth.BluetoothProfile;
import android.bluetooth.le.BluetoothLeScanner;
import android.bluetooth.le.ScanCallback;
import android.bluetooth.le.ScanResult;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.ListView;
import android.widget.SeekBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

public class MainActivity extends AppCompatActivity {
    private static final String TAG = "KayakStabilizer";
    private static final int REQUEST_BLUETOOTH_PERMISSIONS = 1;
    private static final int REQUEST_ENABLE_BT = 2;

    // BLE UUIDs (these should match ESP32 firmware)
    private static final UUID SERVICE_UUID = UUID.fromString("4fafc201-1fb5-459e-8fcc-c5c9c331914b");
    private static final UUID CHARACTERISTIC_UUID_DATA = UUID.fromString("beb5483e-36e1-4688-b7f5-ea07361b26a8");
    private static final UUID CHARACTERISTIC_UUID_COMMAND = UUID.fromString("beb5483f-36e1-4688-b7f5-ea07361b26a8");

    // UI elements
    private Button btnScan, btnConnect, btnStabilizationToggle, btnEmergencyStop;
    private TextView tvConnectionStatus, tvRoll, tvPitch, tvBattery;
    private TextView tvKpValue, tvKiValue, tvKdValue;
    private SeekBar sbKp, sbKi, sbKd;
    private ListView lvDevices;

    // BLE components
    private BluetoothManager bluetoothManager;
    private BluetoothAdapter bluetoothAdapter;
    private BluetoothLeScanner bluetoothLeScanner;
    private BluetoothGatt bluetoothGatt;
    private BluetoothGattCharacteristic dataCharacteristic;
    private BluetoothGattCharacteristic commandCharacteristic;

    // State variables
    private boolean isScanning = false;
    private boolean isConnected = false;
    private boolean stabilizationEnabled = false;
    private List<BluetoothDevice> discoveredDevices = new ArrayList<>();
    private ArrayAdapter<String> deviceAdapter;

    // Handler for UI updates
    private Handler mainHandler = new Handler(Looper.getMainLooper());

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        initializeViews();
        initializeBluetooth();
        setupEventListeners();
        checkPermissions();
    }

    private void initializeViews() {
        btnScan = findViewById(R.id.btnScan);
        btnConnect = findViewById(R.id.btnConnect);
        btnStabilizationToggle = findViewById(R.id.btnStabilizationToggle);
        btnEmergencyStop = findViewById(R.id.btnEmergencyStop);

        tvConnectionStatus = findViewById(R.id.tvConnectionStatus);
        tvRoll = findViewById(R.id.tvRoll);
        tvPitch = findViewById(R.id.tvPitch);
        tvBattery = findViewById(R.id.tvBattery);

        tvKpValue = findViewById(R.id.tvKpValue);
        tvKiValue = findViewById(R.id.tvKiValue);
        tvKdValue = findViewById(R.id.tvKdValue);

        sbKp = findViewById(R.id.sbKp);
        sbKi = findViewById(R.id.sbKi);
        sbKd = findViewById(R.id.sbKd);

        lvDevices = findViewById(R.id.lvDevices);
        deviceAdapter = new ArrayAdapter<>(this, android.R.layout.simple_list_item_1);
        lvDevices.setAdapter(deviceAdapter);
    }

    private void initializeBluetooth() {
        bluetoothManager = (BluetoothManager) getSystemService(Context.BLUETOOTH_SERVICE);
        bluetoothAdapter = bluetoothManager.getAdapter();

        if (bluetoothAdapter == null) {
            showToast(getString(R.string.bluetooth_not_supported));
            finish();
            return;
        }

        bluetoothLeScanner = bluetoothAdapter.getBluetoothLeScanner();
    }

    private void setupEventListeners() {
        btnScan.setOnClickListener(v -> {
            if (!isScanning) {
                startScanning();
            } else {
                stopScanning();
            }
        });

        btnConnect.setOnClickListener(v -> {
            if (!isConnected) {
                // Connect to first discovered device (in real app, let user select)
                if (!discoveredDevices.isEmpty()) {
                    connectToDevice(discoveredDevices.get(0));
                }
            } else {
                disconnectFromDevice();
            }
        });

        btnStabilizationToggle.setOnClickListener(v -> {
            stabilizationEnabled = !stabilizationEnabled;
            updateStabilizationButton();
            sendCommand(stabilizationEnabled ? "STABILIZATION_ON" : "STABILIZATION_OFF");
        });

        btnEmergencyStop.setOnClickListener(v -> sendCommand("EMERGENCY_STOP"));

        setupSeekBarListeners();
        setupDeviceListListener();
    }

    private void setupSeekBarListeners() {
        sbKp.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                if (fromUser && isConnected) {
                    float kpValue = progress / 10.0f;
                    tvKpValue.setText(String.format("%.1f", kpValue));
                    sendCommand("SET_KP:" + kpValue);
                }
            }
            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {}
            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {}
        });

        sbKi.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                if (fromUser && isConnected) {
                    float kiValue = progress / 100.0f;
                    tvKiValue.setText(String.format("%.2f", kiValue));
                    sendCommand("SET_KI:" + kiValue);
                }
            }
            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {}
            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {}
        });

        sbKd.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                if (fromUser && isConnected) {
                    float kdValue = progress / 10.0f;
                    tvKdValue.setText(String.format("%.1f", kdValue));
                    sendCommand("SET_KD:" + kdValue);
                }
            }
            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {}
            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {}
        });
    }

    private void setupDeviceListListener() {
        lvDevices.setOnItemClickListener((parent, view, position, id) -> {
            if (position < discoveredDevices.size()) {
                connectToDevice(discoveredDevices.get(position));
                lvDevices.setVisibility(View.GONE);
            }
        });
    }

    private void checkPermissions() {
        List<String> permissionsNeeded = new ArrayList<>();

        if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION)
                != PackageManager.PERMISSION_GRANTED) {
            permissionsNeeded.add(Manifest.permission.ACCESS_FINE_LOCATION);
        }

        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_SCAN)
                    != PackageManager.PERMISSION_GRANTED) {
                permissionsNeeded.add(Manifest.permission.BLUETOOTH_SCAN);
            }
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT)
                    != PackageManager.PERMISSION_GRANTED) {
                permissionsNeeded.add(Manifest.permission.BLUETOOTH_CONNECT);
            }
        }

        if (!permissionsNeeded.isEmpty()) {
            ActivityCompat.requestPermissions(this,
                    permissionsNeeded.toArray(new String[0]),
                    REQUEST_BLUETOOTH_PERMISSIONS);
        } else {
            enableBluetooth();
        }
    }

    private void enableBluetooth() {
        if (!bluetoothAdapter.isEnabled()) {
            Intent enableBtIntent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
            startActivityForResult(enableBtIntent, REQUEST_ENABLE_BT);
        }
    }

    private void startScanning() {
        if (!hasScanPermission()) {
            showToast(getString(R.string.location_permission_required));
            return;
        }

        discoveredDevices.clear();
        deviceAdapter.clear();
        lvDevices.setVisibility(View.VISIBLE);

        isScanning = true;
        btnScan.setText("Stop Scan");

        bluetoothLeScanner.startScan(scanCallback);
        Log.d(TAG, "Started BLE scanning");

        // Stop scanning after 10 seconds
        mainHandler.postDelayed(() -> {
            if (isScanning) {
                stopScanning();
            }
        }, 10000);
    }

    private void stopScanning() {
        if (isScanning && hasScanPermission()) {
            bluetoothLeScanner.stopScan(scanCallback);
            isScanning = false;
            btnScan.setText(getString(R.string.scan_devices));
            Log.d(TAG, "Stopped BLE scanning");
        }
    }

    private boolean hasScanPermission() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
            return ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_SCAN)
                    == PackageManager.PERMISSION_GRANTED;
        } else {
            return ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION)
                    == PackageManager.PERMISSION_GRANTED;
        }
    }

    private final ScanCallback scanCallback = new ScanCallback() {
        @Override
        public void onScanResult(int callbackType, ScanResult result) {
            BluetoothDevice device = result.getDevice();
            if (device != null && device.getName() != null &&
                    device.getName().contains("Kayak") && !discoveredDevices.contains(device)) {
                discoveredDevices.add(device);
                mainHandler.post(() -> {
                    deviceAdapter.add(device.getName() + "\n" + device.getAddress());
                    deviceAdapter.notifyDataSetChanged();
                });
            }
        }

        @Override
        public void onScanFailed(int errorCode) {
            Log.e(TAG, "Scan failed with error: " + errorCode);
            mainHandler.post(() -> showToast("Scan failed"));
        }
    };

    private void connectToDevice(BluetoothDevice device) {
        if (!hasConnectPermission()) {
            showToast(getString(R.string.permission_denied));
            return;
        }

        stopScanning();
        lvDevices.setVisibility(View.GONE);

        tvConnectionStatus.setText(getString(R.string.connecting));
        bluetoothGatt = device.connectGatt(this, false, gattCallback);
        Log.d(TAG, "Connecting to: " + device.getAddress());
    }

    private void disconnectFromDevice() {
        if (bluetoothGatt != null) {
            bluetoothGatt.disconnect();
        }
    }

    private boolean hasConnectPermission() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
            return ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT)
                    == PackageManager.PERMISSION_GRANTED;
        }
        return true;
    }

    private final BluetoothGattCallback gattCallback = new BluetoothGattCallback() {
        @Override
        public void onConnectionStateChange(BluetoothGatt gatt, int status, int newState) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                if (newState == BluetoothProfile.STATE_CONNECTED) {
                    isConnected = true;
                    mainHandler.post(() -> {
                        tvConnectionStatus.setText(getString(R.string.connected));
                        btnConnect.setText(getString(R.string.disconnect));
                        enableControls(true);
                    });
                    bluetoothGatt.discoverServices();
                    Log.d(TAG, "Connected to GATT server");
                } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                    isConnected = false;
                    mainHandler.post(() -> {
                        tvConnectionStatus.setText(getString(R.string.disconnected));
                        btnConnect.setText(getString(R.string.connect));
                        enableControls(false);
                    });
                    Log.d(TAG, "Disconnected from GATT server");
                }
            } else {
                Log.e(TAG, "Connection state change failed: " + status);
                mainHandler.post(() -> showToast(getString(R.string.connection_failed)));
            }
        }

        @Override
        public void onServicesDiscovered(BluetoothGatt gatt, int status) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                BluetoothGattService service = gatt.getService(SERVICE_UUID);
                if (service != null) {
                    dataCharacteristic = service.getCharacteristic(CHARACTERISTIC_UUID_DATA);
                    commandCharacteristic = service.getCharacteristic(CHARACTERISTIC_UUID_COMMAND);

                    if (dataCharacteristic != null) {
                        bluetoothGatt.setCharacteristicNotification(dataCharacteristic, true);
                    }
                    Log.d(TAG, "Services discovered successfully");
                }
            }
        }

        @Override
        public void onCharacteristicChanged(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic) {
            if (CHARACTERISTIC_UUID_DATA.equals(characteristic.getUuid())) {
                final String data = characteristic.getStringValue(0);
                mainHandler.post(() -> parseAndUpdateSensorData(data));
            }
        }

        @Override
        public void onCharacteristicWrite(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic, int status) {
            if (status != BluetoothGatt.GATT_SUCCESS) {
                Log.e(TAG, "Characteristic write failed: " + status);
            }
        }
    };

    private void sendCommand(String command) {
        if (!isConnected || commandCharacteristic == null) {
            return;
        }

        commandCharacteristic.setValue(command);
        bluetoothGatt.writeCharacteristic(commandCharacteristic);
        Log.d(TAG, "Sent command: " + command);
    }

    private void parseAndUpdateSensorData(String data) {
        try {
            String[] parts = data.split(",");
            for (String part : parts) {
                if (part.contains("ROLL:")) {
                    String rollValue = part.split(":")[1];
                    tvRoll.setText(getString(R.string.roll_label) + rollValue + "°");
                } else if (part.contains("PITCH:")) {
                    String pitchValue = part.split(":")[1];
                    tvPitch.setText(getString(R.string.pitch_label) + pitchValue + "°");
                } else if (part.contains("BATTERY:")) {
                    String batteryValue = part.split(":")[1];
                    tvBattery.setText(getString(R.string.battery_label) + batteryValue + "V");

                    // Check for low battery warning
                    try {
                        float voltage = Float.parseFloat(batteryValue);
                        if (voltage < 3.3f) {
                            showToast(getString(R.string.low_battery_warning));
                        }
                    } catch (NumberFormatException e) {
                        Log.e(TAG, "Invalid battery voltage format: " + batteryValue);
                    }
                }
            }
        } catch (Exception e) {
            Log.e(TAG, "Error parsing sensor data: " + data, e);
        }
    }

    private void updateStabilizationButton() {
        btnStabilizationToggle.setText(stabilizationEnabled ?
                getString(R.string.stabilization_on) : getString(R.string.stabilization_off));
        btnStabilizationToggle.setBackgroundTintList(
                ContextCompat.getColorStateList(this,
                        stabilizationEnabled ? android.R.color.holo_green_dark : android.R.color.holo_red_dark));
    }

    private void enableControls(boolean enabled) {
        btnStabilizationToggle.setEnabled(enabled);
        btnEmergencyStop.setEnabled(enabled);
        sbKp.setEnabled(enabled);
        sbKi.setEnabled(enabled);
        sbKd.setEnabled(enabled);
    }

    private void showToast(String message) {
        Toast.makeText(this, message, Toast.LENGTH_SHORT).show();
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == REQUEST_BLUETOOTH_PERMISSIONS) {
            boolean allGranted = true;
            for (int result : grantResults) {
                if (result != PackageManager.PERMISSION_GRANTED) {
                    allGranted = false;
                    break;
                }
            }
            if (allGranted) {
                enableBluetooth();
            } else {
                showToast(getString(R.string.permission_denied));
            }
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == REQUEST_ENABLE_BT) {
            if (resultCode == RESULT_OK) {
                Log.d(TAG, "Bluetooth enabled");
            } else {
                showToast(getString(R.string.bluetooth_disabled));
            }
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (bluetoothGatt != null) {
            bluetoothGatt.close();
            bluetoothGatt = null;
        }
        stopScanning();
    }
}