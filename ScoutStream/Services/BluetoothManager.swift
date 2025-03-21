//
//  BluetoothManager.swift
//  ScoutStream
//
//  Created by Nathan Nguyen on 2025-03-18.
//

import Foundation
import CoreBluetooth
import Combine

class BluetoothManager: NSObject, ObservableObject {
    // MARK: - Properties
    
    // Published properties to notify the UI
    @Published var devices: [BluetoothDevice] = []
    @Published var isScanning = false
    
    // Core Bluetooth properties
    private var centralManager: CBCentralManager!
    private var discoveredPeripherals = [String: CBPeripheral]()
    
    // Manufacturer data constants
    private enum ManufacturerDataKeys {
        static let temperature = 0x01
        static let humidity = 0x02
        static let velocity = 0x03
        static let co2 = 0x04
    }
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Public Methods
    
    /// Start scanning for BLE devices with extended advertising data
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            print("Bluetooth is not powered on")
            return
        }
        
        // Clear the previous scan results
        devices.removeAll()
        discoveredPeripherals.removeAll()
        
        // Start scanning with options to allow duplicate devices (to get RSSI updates)
        // and to scan for devices that support extended advertising
        let options: [String: Any] = [
            CBCentralManagerScanOptionAllowDuplicatesKey: true
        ]
        
        centralManager.scanForPeripherals(withServices: nil, options: options)
        isScanning = true
    }
    
    /// Stop scanning for BLE devices
    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
    }
    
    // MARK: - Private Methods
    
    /// Parse manufacturer data from advertisement data
    private func parseManufacturerData(from advertisementData: [String: Any]) -> (temperature: Double?, humidity: Double?, velocity: Double?, co2: Int?) {
        // Look for manufacturer data in the advertisement
        guard let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data else {
            return (nil, nil, nil, nil)
        }
        
        var temperature: Double?
        var humidity: Double?
        var velocity: Double?
        var co2: Int?
        
        // Manufacturer data format:
        // Byte 0-1: Manufacturer ID (e.g., 0xFFFF for test/custom)
        // Remaining bytes: Key-Value pairs
        // Each pair: 1 byte key, 2-4 bytes value depending on the type
        
        // Skip manufacturer ID (2 bytes)
        var index = 2
        
        // Parse key-value pairs
        while index < manufacturerData.count {
            // Get the key
            let key = manufacturerData[index]
            index += 1
            
            // Parse values based on key
            switch key {
            case UInt8(ManufacturerDataKeys.temperature):
                // Temperature as 2-byte value (0.1°C resolution)
                if index + 1 < manufacturerData.count {
                    let rawValue = UInt16(manufacturerData[index]) | (UInt16(manufacturerData[index + 1]) << 8)
                    temperature = Double(rawValue) / 10.0
                    index += 2
                }
                
            case UInt8(ManufacturerDataKeys.humidity):
                // Humidity as 2-byte value (0.1% resolution)
                if index + 1 < manufacturerData.count {
                    let rawValue = UInt16(manufacturerData[index]) | (UInt16(manufacturerData[index + 1]) << 8)
                    humidity = Double(rawValue) / 10.0
                    index += 2
                }
                
            case UInt8(ManufacturerDataKeys.velocity):
                // Velocity as 2-byte value (0.01 m/s resolution)
                if index + 1 < manufacturerData.count {
                    let rawValue = UInt16(manufacturerData[index]) | (UInt16(manufacturerData[index + 1]) << 8)
                    velocity = Double(rawValue) / 100.0
                    index += 2
                }
                
            case UInt8(ManufacturerDataKeys.co2):
                // CO2 as 2-byte value (1 ppm resolution)
                if index + 1 < manufacturerData.count {
                    let rawValue = UInt16(manufacturerData[index]) | (UInt16(manufacturerData[index + 1]) << 8)
                    co2 = Int(rawValue)
                    index += 2
                }
                
            default:
                // Unknown key, skip (assume 2-byte value)
                index += 2
            }
        }
        
        return (temperature, humidity, velocity, co2)
    }
    
    /// Update or add a device to the list
    private func updateDevice(peripheral: CBPeripheral, rssi: Int, advertisementData: [String: Any]) {
        let identifier = peripheral.identifier.uuidString
        
        // Parse manufacturer data to get sensor readings
        let sensorData = parseManufacturerData(from: advertisementData)
        
        // Get device name (use identifier if no name is available)
        let deviceName = peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? "Unknown Device"
        
        // Check if this device is already in our list
        if let index = devices.firstIndex(where: { $0.id.uuidString == identifier }) {
            // Update existing device
            var updatedDevice = devices[index]
            updatedDevice.rssi = rssi
            updatedDevice.name = deviceName
            
            // Update sensor values if they are available
            if let temp = sensorData.temperature {
                updatedDevice.temperature = temp
            }
            
            if let humidity = sensorData.humidity {
                updatedDevice.humidity = humidity
            }
            
            if let velocity = sensorData.velocity {
                updatedDevice.velocity = velocity
            }
            
            if let co2 = sensorData.co2 {
                updatedDevice.co2 = co2
            }
            
            devices[index] = updatedDevice
        } else {
            // Add new device
            let newDevice = BluetoothDevice(
                id: peripheral.identifier,
                name: deviceName,
                rssi: rssi,
                temperature: sensorData.temperature,
                humidity: sensorData.humidity,
                velocity: sensorData.velocity,
                co2: sensorData.co2
            )
            
            devices.append(newDevice)
            discoveredPeripherals[identifier] = peripheral
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth is powered on")
            // Auto-start scanning when Bluetooth is ready
            if isScanning {
                startScanning()
            }
        case .poweredOff:
            print("Bluetooth is powered off")
            isScanning = false
        case .resetting:
            print("Bluetooth is resetting")
        case .unauthorized:
            print("Bluetooth is unauthorized")
        case .unsupported:
            print("Bluetooth is unsupported")
        case .unknown:
            print("Bluetooth state is unknown")
        @unknown default:
            print("Unknown Bluetooth state")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        // Process discovered device
        DispatchQueue.main.async {
            self.updateDevice(peripheral: peripheral, rssi: RSSI.intValue, advertisementData: advertisementData)
        }
    }
}
