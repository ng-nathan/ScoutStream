# Scout Stream App (End-user Prototype)

This is a proof-of-concept mobile application designed to demonstrate Bluetooth Low Energy (BLE) Extended Advertising data scanning on iOS devices.

This app serves a primarily visual purpose—allowing users to see how extended advertising packets are received, parsed, and displayed in real time. It helps validate the capability and behavior of iOS BLE stacks when handling larger advertising payloads.

## Requirement

- iOS 13+
- macOS for app development

## How It Works

### Permission

- Add permission via `Info.plit`
  - NSBluetoothAlwaysUsageDescription, UIBackgroundModes (bluetooth-central, processing)
  - _**Note**: XCode has a different interface to edit Info.plit_

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>NSBluetoothAlwaysUsageDescription</key>
	<string>This app needs Bluetooth to scan for and connect to Scout sensors.</string>
	<key>NSAccessorySetupBluetoothCompanyIdentifiers</key>
	<array>
		<string>3101</string>
	</array>
	<key>UIBackgroundModes</key>
	<array>
		<string>bluetooth-central</string>
		<string>processing</string>
	</array>
</dict>
</plist>
```
- Permission check automatically triggered by CoreBluetooth
- No manual prompt needed; request is implicit on first use of CBCentralManager

### BLE Scanning

- Initiated by calling `startScanning()`
- Uses `centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])`
- Stops on `stopScanning()` call
- Scan results handled in `centralManager(_:didDiscover:advertisementData:rssi:)`
- Scan settings:
  - Allows duplicate packets (needed for RSSI/sensor updates)
  - Accepts all services (nil = all devices)
  - No explicit extended adv setting (iOS handles this internally)
  - Payload inferred by length/format of manufacturer data

```swift
// Start scan
centralManager.scanForPeripherals(
    withServices: nil,
    options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
)

// Stop scan
centralManager.stopScan()

// Scan result back
func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                    advertisementData: [String: Any], rssi RSSI: NSNumber) {
    updateDevice(peripheral: peripheral, rssi: RSSI.intValue, advertisementData: advertisementData)
}
```
