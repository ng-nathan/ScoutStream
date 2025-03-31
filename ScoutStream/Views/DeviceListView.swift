//
//  DeviceListView.swift
//  ScoutStream
//
//  Created by Nathan Nguyen on 2025-03-17.
//

import SwiftUI

struct DeviceListView: View {
    // Use the BluetoothManager with the new Observation framework
    @State private var bluetoothManager = BluetoothManager()
    
    // No longer need these computed properties since we can directly access observed properties
    @State private var searchText: String = ""
    
    // Filtered devices based on search text
    private var filteredDevices: [BluetoothDevice] {
        if searchText.isEmpty {
            return bluetoothManager.devices
        } else {
            return bluetoothManager.devices.filter { device in
                device.name.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        VStack {
            // Scanning status header
            HStack {
                Image(systemName: bluetoothManager.isScanning ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
                    .font(.system(size: 14))
                    .foregroundColor(bluetoothManager.isScanning ? .blue : .gray)
                
                Text(bluetoothManager.isScanning ? "Scanning for devices..." : "Scan paused")
                    .font(.caption)
                    .foregroundColor(bluetoothManager.isScanning ? .primary : .secondary)
                
                Spacer()
                
                Button(action: {
                    if bluetoothManager.isScanning {
                        bluetoothManager.stopScanning()
                    } else {
                        bluetoothManager.startScanning()
                    }
                }) {
                    Text(bluetoothManager.isScanning ? "Stop" : "Start")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(bluetoothManager.isScanning ? Color.red.opacity(0.2) : Color.blue.opacity(0.2))
                        .foregroundColor(bluetoothManager.isScanning ? .red : .blue)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search devices", text: $searchText)
                    .foregroundColor(.primary)
                
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
            .padding(.top, 8)
            
            // Device grid (2 columns)
            ScrollView {
                if filteredDevices.isEmpty {
                    VStack {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                            .padding()
                        
                        Text("No matching devices found")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 50)
                } else {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        ForEach(filteredDevices) { device in
                            NavigationLink(destination: DeviceDetailView(device: device)) {
                                DeviceGridItem(device: device)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                }
            }
        }
    }
}

#Preview {
    DeviceListView()
}
