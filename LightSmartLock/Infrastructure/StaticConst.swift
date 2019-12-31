//
//  StaticConst.swift
//  LightSmartLock
//
//  Created by mugua on 2019/11/19.
//  Copyright © 2019 mugua. All rights reserved.
//

import Foundation
import UIKit

let kLSRem = UIScreen.main.bounds.width / 375

enum NotificationRefreshType {
    case deleteLock
    case addLock
    case deleteScene
    case updateScene
    case changeDigitalPwd(String?)
}

extension NSNotification.Name {
    
    static let loginStateDidChange = NSNotification.Name(rawValue: "loginStateDidChange")
    static let statuBarDidChange = NSNotification.Name(rawValue: "statuBarDidChange")
    static let refreshState = NSNotification.Name(rawValue: "refreshState")
    static let animationRestart = NSNotification.Name(rawValue: "animationRestart")
    static let siriOpenDoor = NSNotification.Name(rawValue: "siriOpenDoor")
}


struct PlatformKey {
    static let gouda = "caed09caa3daeca4a11a9eb671294d65"
}
