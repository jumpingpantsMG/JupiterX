//
//  Device.swift
//  JupiterX
//
//  Created by Jaiden Kumar on 1/5/26.
//


import Foundation
import UIKit
import Network
import CoreTelephony

final class Device {

    // MARK: - Device Basics

    static var name: String {
        UIDevice.current.name
    }

    static var model: String {
        UIDevice.current.model
    }

    static var systemName: String {
        UIDevice.current.systemName
    }

    static var systemVersion: String {
        UIDevice.current.systemVersion
    }

    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    static var isIPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }

    // MARK: - Orientation

    static var deviceOrientation: UIDeviceOrientation {
        UIDevice.current.orientation
    }

    static var interfaceOrientation: UIInterfaceOrientation? {
        UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .effectiveGeometry
            .interfaceOrientation
    }

    static var isLandscape: Bool {
        interfaceOrientation?.isLandscape ?? false
    }

    static var isPortrait: Bool {
        interfaceOrientation?.isPortrait ?? false
    }

    // MARK: - Network Status

    private static let monitor = NWPathMonitor()
    private static var currentPath: NWPath?

    static func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { path in
            currentPath = path
        }
        monitor.start(queue: DispatchQueue.global(qos: .background))
    }

    static var isConnectedToInternet: Bool {
        currentPath?.status == .satisfied
    }

    static var isUsingWiFi: Bool {
        currentPath?.usesInterfaceType(.wifi) ?? false
    }

    static var isUsingCellular: Bool {
        currentPath?.usesInterfaceType(.cellular) ?? false
    }

    // MARK: - Cellular Info

    static var cellularTechnology: String? {
        let networkInfo = CTTelephonyNetworkInfo()
        return networkInfo.serviceCurrentRadioAccessTechnology?.values.first
    }

    // MARK: - Battery

    static var batteryLevel: Float {
        UIDevice.current.isBatteryMonitoringEnabled = true
        return UIDevice.current.batteryLevel
    }

    static var batteryState: UIDevice.BatteryState {
        UIDevice.current.isBatteryMonitoringEnabled = true
        return UIDevice.current.batteryState
    }
}
