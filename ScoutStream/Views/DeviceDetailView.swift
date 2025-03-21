//
//  DeviceDetailView.swift
//  ScoutStream
//
//  Created by Nathan Nguyen on 2025-03-17.
//

import SwiftUI

struct DeviceDetailView: View {
    let device: BluetoothDevice
    @Environment(\.presentationMode) var presentationMode
    
    // Parse location from device name (e.g., Scout_F1Z2 -> Floor: 1, Zone: 2)
    private var locationInfo: (floor: String, zone: String)? {
        let parts = device.name.split(separator: "_")
        guard parts.count > 1, let locationCode = parts.last else {
            return nil
        }
        
        // Try to extract F{floor}Z{zone} pattern
        if let floorMatch = locationCode.range(of: "F\\d+", options: .regularExpression),
           let zoneMatch = locationCode.range(of: "Z\\d+", options: .regularExpression) {
            
            let floorCode = locationCode[floorMatch]
            let zoneCode = locationCode[zoneMatch]
            
            let floorNumber = floorCode.dropFirst() // Remove "F"
            let zoneNumber = zoneCode.dropFirst() // Remove "Z"
            
            return (floor: String(floorNumber), zone: String(zoneNumber))
        }
        
        return nil
    }
    
    // Get temperature color based on value
    private var temperatureColor: Color {
        guard let temp = device.temperature else { return .gray }
        
        if temp < 18 {
            return .blue
        } else if temp < 22 {
            return .green
        } else if temp < 26 {
            return .orange
        } else {
            return .red
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with device info
                headerSection
                
                // Temperature circle (always show)
                temperatureCircle(temperature: device.temperature)
                
                // Humidity bar (always show)
                humidityBar(humidity: device.humidity)
                
                // Velocity and CO2 grid (always show)
                velocityCO2Grid
                
                // Device details
                deviceDetailsSection
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Device Details")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    // This will pop the current view off the navigation stack
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack(spacing: 16) {
            // Device icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "wave.3.right")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }
            
            // Device info
            VStack(alignment: .leading, spacing: 4) {
                Text(device.name)
                    .font(.title3)
                    .fontWeight(.bold)
                
                HStack {
                    Label(locationInfo != nil ? "Floor \(locationInfo!.floor)" : "Floor N/A", systemImage: "building.2")
                        .font(.subheadline)
                    
                    Spacer()
                        .frame(width: 16)
                    
                    Label(locationInfo != nil ? "Zone \(locationInfo!.zone)" : "Zone N/A", systemImage: "mappin.and.ellipse")
                        .font(.subheadline)
                }
                .foregroundColor(.secondary)
                
                // Signal strength
                HStack {
                    Text("RSSI: \(device.rssi) dBm")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 2) {
                        ForEach(0..<4) { index in
                            Rectangle()
                                .fill(index < device.signalStrength ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 3, height: 8 + CGFloat(index) * 3)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Temperature Circle
    private func temperatureCircle(temperature: Double?) -> some View {
        VStack {
            Text("Temperature")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ZStack {
                // Outer circle
                Circle()
                    .stroke(temperatureColor.opacity(0.3), lineWidth: 20)
                    .frame(width: 200, height: 200)
                
                // Inner circle with color
                Circle()
                    .fill(temperatureColor.opacity(0.2))
                    .frame(width: 180, height: 180)
                
                // Temperature value
                VStack(spacing: 0) {
                    if let temp = temperature {
                        Text(String(format: "%.1f", temp))
                            .font(.system(size: 48, weight: .bold))
                        
                        Text("°C")
                            .font(.system(size: 24))
                            .offset(y: -5)
                    } else {
                        Text("N/A")
                            .font(.system(size: 48, weight: .bold))
                    }
                }
                .foregroundColor(temperatureColor)
            }
            .padding(.vertical, 10)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Humidity Bar
    private func humidityBar(humidity: Double?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Humidity")
                .font(.headline)
            
            ZStack(alignment: .leading) {
                // Background bar
                Rectangle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(height: 30)
                    .cornerRadius(15)
                
                if let hum = humidity {
                    // Filled bar
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .cyan]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(CGFloat(hum) / 100.0 * UIScreen.main.bounds.width * 0.85, 30), height: 30)
                        .cornerRadius(15)
                    
                    // Percentage text
                    Text("\(Int(hum))%")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 15)
                        .shadow(radius: 1)
                } else {
                    // N/A text
                    Text("N/A")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 15)
                }
            }
            
            Text("Relative humidity")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Velocity and CO2 Grid
    private var velocityCO2Grid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Other Readings")
                .font(.headline)
            
            HStack(spacing: 15) {
                // Velocity
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "wind")
                            .foregroundColor(.green)
                        
                        Text("Air Flow")
                            .font(.subheadline)
                    }
                    
                    if let velocity = device.velocity {
                        Text(String(format: "%.1f", velocity))
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.green)
                        
                        Text("m/s")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("N/A")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.1))
                .cornerRadius(10)
                
                // CO2
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "aqi.medium")
                            .foregroundColor(.purple)
                        
                        Text("CO₂")
                            .font(.subheadline)
                    }
                    
                    if let co2Value = device.co2 {
                        Text("\(co2Value)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.purple)
                        
                        Text("ppm")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("N/A")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Device Details Section
    private var deviceDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Device Details")
                .font(.headline)
            
            detailRow(title: "Device ID", value: device.id.uuidString)
            detailRow(title: "Device Name", value: device.name)
            detailRow(title: "Signal Strength", value: "\(device.rssi) dBm")
            
            if let location = locationInfo {
                detailRow(title: "Location", value: "Floor \(location.floor), Zone \(location.zone)")
            }
            
            detailRow(title: "Last Updated", value: "Just now")
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    DeviceDetailView(device: BluetoothDevice(
        name: "Scout_F2Z3",
        rssi: -75,
        temperature: 22.5,
        humidity: 48.2,
        velocity: 1.7,
        co2: 750
    ))
}
            
