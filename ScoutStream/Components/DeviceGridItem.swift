//
//  DeviceGridItem.swift
//  ScoutStream
//
//  Created by Nathan Nguyen on 2025-03-18.
//

import SwiftUI

struct DeviceGridItem: View {
    let device: BluetoothDevice
    
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Device name
            Text(device.name)
                .font(.system(size: 14, weight: .medium))
                .lineLimit(1)
            
            // Location info - always display
            HStack {
                Label(locationInfo != nil ? "Floor \(locationInfo!.floor)" : "N/A", systemImage: "building.2")
                    .font(.system(size: 12))
                
                Spacer()
                
                Label(locationInfo != nil ? "Zone \(locationInfo!.zone)" : "N/A", systemImage: "mappin")
                    .font(.system(size: 12))
            }
            .foregroundColor(.secondary)
            
            // Signal strength indicator
            HStack {
                // RSSI value
                Text("\(device.rssi) dBm")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Signal bars
                HStack(spacing: 2) {
                    ForEach(0..<4) { index in
                        Rectangle()
                            .fill(index < device.signalStrength ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 2, height: 6 + CGFloat(index) * 2)
                    }
                }
            }
        }
        .padding(10)
        .frame(height: 90)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

struct DeviceGridItem_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            DeviceGridItem(device: BluetoothDevice(
                name: "Scout_F1Z2",
                rssi: -67,
                temperature: 23.4,
                humidity: 45.2,
                velocity: nil,
                co2: nil
            ))
            .frame(width: 170)
            
            DeviceGridItem(device: BluetoothDevice(
                name: "Scout_F3Z5",
                rssi: -82,
                temperature: 21.8,
                humidity: 38.5,
                velocity: 1.2,
                co2: 650
            ))
            .frame(width: 170)
            
            DeviceGridItem(device: BluetoothDevice(
                name: "Unknown Device",
                rssi: -95,
                temperature: nil,
                humidity: nil,
                velocity: nil,
                co2: nil
            ))
            .frame(width: 170)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .previewLayout(.sizeThatFits)
    }
}
