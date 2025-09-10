package com.example.kayakstabilizer;

import android.Manifest;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothSocket;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.View;
import android.widget.Button;
import android.widget.SeekBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.UUID;

public class MainActivity extends AppCompatActivity {
    private static final UUID BT_UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB");
    private static final int REQUEST_BLUETOOTH_PERMISSIONS = 1;

    private BluetoothAdapter bluetoothAdapter;
    private BluetoothSocket bluetoothSocket;
    private OutputStream outputStream;
    private InputStream inputStream;
    private boolean isConnected = false;

    private TextView tvRoll, tvPitch, tvBattery, tvStatus;
    private SeekBar sbKp, sbKi, sbKd;
    private Button btnConnect, btnEmergencyReset;

    private Handler handler = new Handler(Looper.getMainLooper());

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        initializeViews();
        setupBluetooth();
        setupSeekBars();
        setupButtons();
    }

    private void initializeViews() {
        tvRoll = findViewById(R.id.tvRoll);
        tvPitch = findViewById(R.id.tvPitch);
        tvBattery = findViewById(R.id.tvBattery);
        tvStatus = findViewById(R.id.tvStatus);
        sbKp = findViewById(R.id.sbKp);
        sbKi = findViewById(R.id.sbKi);
        sbKd = findViewById(R.id.sbKd);
        btnConnect = findViewById(R.id.btnConnect);
        btnEmergencyReset = findViewById(R.id.btnEmergencyReset);
    }

    private void setupBluetooth() {
        bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        if (bluetoothAdapter == null) {
            Toast.makeText(this, "Bluetooth not supported", Toast.LENGTH_SHORT).show();
            finish();
        }

        if (!bluetoothAdapter.isEnabled()) {
            Toast.makeText(this, "Please enable Bluetooth", Toast.LENGTH_SHORT).show();
        }
    }

    private void setupSeekBars() {
        sbKp.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                if (fromUser && isConnected) {
                    sendCommand("SET_KP:" + (progress / 10.0f));
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
                    sendCommand("SET_KI:" + (progress / 100.0f));
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
                    sendCommand("SET_KD:" + (progress / 10.0f));
                }
            }
            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {}
            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {}
        });
    }

    private void setupButtons() {
        btnConnect.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (!isConnected) {
                    connectToDevice();
                } else {
                    disconnectFromDevice();
                }
            }
        });

        btnEmergencyReset.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (isConnected) {
                    sendCommand("RESET_EMERGENCY");
                }
            }
        });
    }

    private void connectToDevice() {
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this, new String[]{Manifest.permission.BLUETOOTH_CONNECT}, REQUEST_BLUETOOTH_PERMISSIONS);
            return;
        }

        try {
            BluetoothDevice device = bluetoothAdapter.getRemoteDevice("ESP32_ADDRESS"); // Replace with actual ESP32 MAC address
            bluetoothSocket = device.createRfcommSocketToServiceRecord(BT_UUID);
            bluetoothSocket.connect();
            outputStream = bluetoothSocket.getOutputStream();
            inputStream = bluetoothSocket.getInputStream();
            isConnected = true;
            btnConnect.setText("Disconnect");
            startDataListener();
            Toast.makeText(this, "Connected to Kayak Stabilizer", Toast.LENGTH_SHORT).show();
        } catch (IOException e) {
            Toast.makeText(this, "Connection failed: " + e.getMessage(), Toast.LENGTH_SHORT).show();
        }
    }

    private void disconnectFromDevice() {
        try {
            if (bluetoothSocket != null) {
                bluetoothSocket.close();
            }
            isConnected = false;
            btnConnect.setText("Disconnect");
            Toast.makeText(this, "Disconnected", Toast.LENGTH_SHORT).show();
        } catch (IOException e) {
            Toast.makeText(this, "Disconnection error", Toast.LENGTH_SHORT).show();
        }
    }

    private void sendCommand(String command) {
        if (isConnected && outputStream != null) {
            try {
                outputStream.write((command + "\n").getBytes());
            } catch (IOException e) {
                Toast.makeText(this, "Send failed", Toast.LENGTH_SHORT).show();
            }
        }
    }

    private void startDataListener() {
        new Thread(new Runnable() {
            @Override
            public void run() {
                byte[] buffer = new byte[1024];
                int bytes;
                while (isConnected) {
                    try {
                        bytes = inputStream.read(buffer);
                        String data = new String(buffer, 0, bytes);
                        parseAndUpdateUI(data);
                    } catch (IOException e) {
                        break;
                    }
                }
            }
        }).start();
    }

    private void parseAndUpdateUI(String data) {
        handler.post(new Runnable() {
            @Override
            public void run() {
                // Parse data like "ROLL:1.23,PITCH:-0.45,L_SERVO:95,R_SERVO:85"
                String[] parts = data.split(",");
                for (String part : parts) {
                    if (part.startsWith("ROLL:")) {
                        tvRoll.setText("Roll: " + part.substring(5) + "°");
                    } else if (part.startsWith("PITCH:")) {
                        tvPitch.setText("Pitch: " + part.substring(6) + "°");
                    } else if (part.startsWith("BATTERY:")) {
                        tvBattery.setText("Battery: " + part.substring(8) + "V");
                    }
                }
            }
        });
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        disconnectFromDevice();
    }
}