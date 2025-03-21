//
//  BluetoothDevice.swift
//  ScoutStream
//
//  Created by Nathan Nguyen on 2025-03-18.
//

import Foundation

struct BluetoothDevice: Identifiable {
    var id = UUID()
    var name: String
    var rssi: Int
    
    // Sensor values
    var temperature: Double?
    var humidity: Double?
    var velocity: Double?
    var co2: Int?
    
    // Mock signal strength
    var signalStrength: Int {
        if rssi >= -60 {
            return 3 // strong
        } else if rssi >= -80 {
            return 2 // medium
        } else if rssi >= -90 {
            return 1 // weak
        } else {
            return 0 // might as well give up
        }
    }
}
