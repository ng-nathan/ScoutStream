//
//  ContentView.swift
//  ScoutStream
//
//  Created by Nathan Nguyen on 2025-03-16.
//

import SwiftUI
import CoreBluetooth
import Combine

// Model to store discovered device information
struct DiscoveredDevice: Identifiable, Hashable {
    let id: UUID
    let name: String
    let rssi: Int
    let advertisementData: [String: Any]
    
    var displayName: String {
        return name.isEmpty ? "Unknown Device" : name
    }
    
    var advertisementDataDescription: String {
        var result = ""
        for (key, value) in advertisementData {
            if let data = value as? Data {
                result += "\(key): \(data.hexString)\n"
            } else {
                result += "\(key): \(value)\n"
            }
        }
        return result
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: DiscoveredDevice, rhs: DiscoveredDevice) -> Bool {
        return lhs.id == rhs.id
    }
}

// Utility extension to display Data as hex string
extension Data {
    var hexString: String {
        return self.map { String(format: "%02X", $0) }.joined(separator: " ")
    }
}

// BLE Scanner class that handles CoreBluetooth operations
class BLEScanner: NSObject, ObservableObject {
    @Published var discoveredDevices: [DiscoveredDevice] = []
    
    private var centralManager: CBCentralManager!
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }
    
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            print("Bluetooth is not powered on")
            return
        }
        
        // Use simple scan options
        let scanOptions: [String: Any] = [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        
        centralManager.scanForPeripherals(withServices: nil, options: scanOptions)
        print("Started scanning")
    }
    
    func stopScanning() {
        centralManager.stopScan()
        print("Stopped scanning")
    }
    
    func clearDevices() {
        discoveredDevices.removeAll()
    }
}

// MARK: - CBCentralManagerDelegate
extension BLEScanner: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth is powered on")
            startScanning()
        case .poweredOff:
            print("Bluetooth is powered off")
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
        print("Device: \(peripheral.name ?? "Unknown"), RSSI: \(RSSI)")
        
        // Create device model
        let device = DiscoveredDevice(
            id: peripheral.identifier,
            name: peripheral.name ?? "",
            rssi: RSSI.intValue,
            advertisementData: advertisementData
        )
        
        // Update list on main thread
        DispatchQueue.main.async {
            // Check if device already exists
            if let index = self.discoveredDevices.firstIndex(where: { $0.id == device.id }) {
                // Update existing device
                self.discoveredDevices[index] = device
            } else {
                // Add new device
                self.discoveredDevices.append(device)
            }
        }
    }
}

// MARK: - SwiftUI Views
struct ContentView: View {
    @StateObject private var scanner = BLEScanner()
    @State private var isScanning = false
    @State private var searchText = ""
    
    var filteredDevices: [DiscoveredDevice] {
        if searchText.isEmpty {
            return scanner.discoveredDevices
        } else {
            return scanner.discoveredDevices.filter {
                $0.displayName.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search devices", text: $searchText)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Device list
                if filteredDevices.isEmpty {
                    VStack {
                        Spacer()
                        Text(searchText.isEmpty ? "No devices found" : "No matching devices")
                            .foregroundColor(.gray)
                        Text(searchText.isEmpty ? "Make sure Bluetooth is enabled" : "Try a different search term")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(filteredDevices) { device in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(device.displayName)
                                    .font(.headline)
                                
                                Text("RSSI: \(device.rssi) dBm")
                                    .font(.caption)
                                
                                Text("ID: \(device.id.uuidString)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Text("Advertisement Data:")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                
                                Text(device.advertisementDataDescription)
                                    .font(.system(.caption, design: .monospaced))
                                    .lineLimit(6)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                // Control buttons
                HStack(spacing: 20) {
                    Button(action: {
                        if isScanning {
                            scanner.stopScanning()
                        } else {
                            scanner.startScanning()
                        }
                        isScanning.toggle()
                    }) {
                        Text(isScanning ? "Stop Scanning" : "Start Scanning")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(isScanning ? Color.red : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        scanner.clearDevices()
                    }) {
                        Text("Clear")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("BLE Scanner")
            .onAppear {
                // Auto-start scanning when view appears
                scanner.startScanning()
                isScanning = true
            }
            .onDisappear {
                // Stop scanning when view disappears
                scanner.stopScanning()
                isScanning = false
            }
        }
    }
}

#Preview {
    ContentView()
}
