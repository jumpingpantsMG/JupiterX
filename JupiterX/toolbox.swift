//
//  toolbox.swift
//  JupiterX
//
//  Created by Jaiden Kumar on 1/7/26.
//

import SwiftUI

struct toolbox {
    
    func readUserDefault<T>(_ key: String, defaultValue: T) -> T {
        return UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
    }
    
}
