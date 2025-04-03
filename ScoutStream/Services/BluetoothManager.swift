//
//  BluetoothManager.swift
//  ScoutStream
//
//  Created by Nathan Nguyen on 2025-03-18.
//

import Foundation
import CoreBluetooth
import Combine

extension Data {
    var hexDescription: String {
        self.map { String(format: "%02X", $0) }.joined()
    }
}

@Observable
final class BluetoothManager: NSObject {
    // MARK: - Published Properties
    
    var devices: [BluetoothDevice] = []
    var isScanning = false
    var bluetoothState: CBManagerState = .unknown
    
    // MARK: - Private Properties
    
    private var centralManager: CBCentralManager!
    private var discoveredPeripherals: [UUID: CBPeripheral] = [:]
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        
        // Initialize with a restore identifier to support state restoration
        let options: [String: Any] = [
            CBCentralManagerOptionRestoreIdentifierKey: "ScoutStreamCentralManager"
        ]
        
        centralManager = CBCentralManager(delegate: self, queue: nil, options: options)
    }
    
    // MARK: - Public Methods
    
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            print("Bluetooth is not powered on")
            return
        }
        
        // Clear previous scan results
        devices.removeAll()
        discoveredPeripherals.removeAll()
        
        // Configure scan options to allow duplicate device discovery for RSSI updates
        let scanOptions: [String: Any] = [
            CBCentralManagerScanOptionAllowDuplicatesKey: true
        ]
        
        centralManager.scanForPeripherals(withServices: nil, options: scanOptions)
        isScanning = true
        print("Started scanning for BLE devices")
    }
    
    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
        print("Stopped scanning for BLE devices")
    }
    
    // MARK: - Private Methods
    
    private func isScoutDevice(name: String?) -> Bool {
        guard let name else { return false }
        return name.localizedCaseInsensitiveContains("scout")
    }
    
    private func processManufacturerData(_ manufacturerData: Data) -> (String, String, String, String) {
        // Skip the first 2 bytes (company identifier "3101")
        guard manufacturerData.count > 2 else {
            return ("", "", "", "")
        }
        
        // Extract the data portion (skip company ID)
        let dataBytes = manufacturerData.subdata(in: 2..<manufacturerData.count)
        
        // Try to convert to ASCII string
        if let asciiString = String(data: dataBytes, encoding: .ascii) {
            print("Processed data (after removing company ID): \(asciiString)")
            
            if asciiString.contains(",") {
                return parseManufacturerData(asciiString)
            }
        }
        
        return ("", "", "", "")
    }
    
    private func updateDevice(peripheral: CBPeripheral, rssi: Int, advertisementData: [String: Any]) {
        // Get device name (use identifier if no name is available)
        let deviceName = peripheral.name ??
                         advertisementData[CBAdvertisementDataLocalNameKey] as? String ??
                         "Unknown Device"
        
        // Only process Scout devices
        guard isScoutDevice(name: deviceName) else { return }
        
        let id = peripheral.identifier
        
        // Check if device exists in our list
        let deviceIndex = devices.firstIndex { $0.id == id }
        let existingDevice = deviceIndex.map { devices[$0] }
        
        // Initialize with existing data or nil
        var temperature = existingDevice?.temperature
        var humidity = existingDevice?.humidity
        var velocity = existingDevice?.velocity
        var co2 = existingDevice?.co2
        
        // Process manufacturer data if available
        if let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
            print("Raw manufacturer data: \(manufacturerData as NSData)")
            print("Hex data: \(manufacturerData.hexDescription)")
            
            // Always use the processManufacturerData method which removes the company ID
            let (tempStr, humidStr, velStr, carbonDioxideStr) = processManufacturerData(manufacturerData)
            
            // Convert strings to appropriate numeric types if we got valid values
            if !tempStr.isEmpty { temperature = Double(tempStr) }
            if !humidStr.isEmpty { humidity = Double(humidStr) }
            if !velStr.isEmpty { velocity = Double(velStr) }
            if !carbonDioxideStr.isEmpty { co2 = Int(carbonDioxideStr) }
            
            if !tempStr.isEmpty {
                print("Processed sensor values - Temp: \(tempStr)°C, Humidity: \(humidStr)%, Velocity: \(velStr)m/s, CO2: \(carbonDioxideStr)ppm")
            }
        }
        
        if let index = deviceIndex {
            // Update existing device
            var updatedDevice = devices[index]
            updatedDevice.rssi = rssi
            updatedDevice.name = deviceName
            
            // Only update values if we got new data
            if let temperature { updatedDevice.temperature = temperature }
            if let humidity { updatedDevice.humidity = humidity }
            if let velocity { updatedDevice.velocity = velocity }
            if let co2 { updatedDevice.co2 = co2 }
            
            devices[index] = updatedDevice
        } else {
            // Add new device
            let newDevice = BluetoothDevice(
                id: peripheral.identifier,
                name: deviceName,
                rssi: rssi,
                temperature: temperature,
                humidity: humidity,
                velocity: velocity,
                co2: co2
            )
            
            devices.append(newDevice)
            discoveredPeripherals[id] = peripheral
        }
    }
    
    private func parseManufacturerData(_ data: String) -> (String, String, String, String) {
        let components = data.components(separatedBy: ",")
        
        guard components.count >= 4 else {
            print("Warning: Invalid data format: \(data)")
            return ("", "", "", "")
        }
        
        return (
            components[0].trimmingCharacters(in: .whitespacesAndNewlines),
            components[1].trimmingCharacters(in: .whitespacesAndNewlines),
            components[2].trimmingCharacters(in: .whitespacesAndNewlines),
            components[3].trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}

// MARK: - CBCentralManagerDelegate

extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        bluetoothState = central.state
        
        switch central.state {
        case .poweredOn:
            print("Bluetooth is powered on")
            if isScanning {
                startScanning()
            }
        case .poweredOff:
            print("Bluetooth is powered off")
            isScanning = false
            devices.removeAll()
        default:
            print("Bluetooth state changed: \(central.state)")
            isScanning = false
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                      advertisementData: [String: Any], rssi RSSI: NSNumber) {
        Task { @MainActor in
            updateDevice(peripheral: peripheral, rssi: RSSI.intValue, advertisementData: advertisementData)
        }
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        if let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            for peripheral in peripherals {
                print("Restored peripheral: \(peripheral.name ?? "Unknown")")
                discoveredPeripherals[peripheral.identifier] = peripheral
            }
        }
        
        if isScanning && central.state == .poweredOn {
            startScanning()
        }
    }
}
