//
//  LSLUser.swift
//  LightSmartLock
//
//  Created by mugua on 2019/11/19.
//  Copyright © 2019 mugua. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

class LSLUser: NSObject {
    
    private override init() {
        super.init()
        
        changeableScene.accept(self.scene)
        changeableUserInfo.accept(self.user)
    }
    
    private static let instance = LSLUser()
    
    static func current() -> LSLUser {
        return LSLUser.instance
    }
    
    func logout() {
        
        BluetoothPapa.shareInstance.cancelPeripheralConnection()
        
        JPUSHService.deleteAlias({ (code, alias, seq) in
            print("极光注册别名:\(String(describing: alias))")
        }, seq: 1)
        JPUSHService.resetBadge()
        
        if let t = token?.accessToken {
            AuthAPI.requestMapBool(.logout(token: t))
                .delaySubscription(.seconds(2), scheduler: MainScheduler.instance)
                .subscribe()
                .disposed(by: rx.disposeBag)
        }
        
        if let userId = token?.userId {
            let diskStorage = NetworkDiskStorage(autoCleanTrash: false, path: "lightSmartLock.network")
            let deleteDb = diskStorage.deleteDataBy(id: userId)
            print("数据库网络缓存文件删除:\(deleteDb ? "成功" : "失败")")
        }
       
        Keys.allCases.forEach {
            print("已删除Key:\($0.rawValue)")
            LocalArchiver.remove(key: $0.rawValue)
        }

        UIApplication.shared.applicationIconBadgeNumber = 0

        let shareUserDefault = UserDefaults(suiteName: ShareUserDefaultsKey.groupId.rawValue)
        ShareUserDefaultsKey.allCases.forEach {
            shareUserDefault?.removeObject(forKey: $0.rawValue)
            shareUserDefault?.synchronize()
        }
        
        changeableUserInfo.accept(nil)
        changeableToken.accept(nil)
    }
    
    var token: AccessTokenModel? {
        set {
            guard let entity = newValue?.toJSONString() else { return }
            LocalArchiver.save(key: LSLUser.Keys.token.rawValue, value: entity)
            let shareUserDefault = UserDefaults(suiteName: ShareUserDefaultsKey.groupId.rawValue)
            shareUserDefault?.set(entity, forKey: ShareUserDefaultsKey.token.rawValue)
            shareUserDefault?.synchronize()
        }
        
        get {
            let json = LocalArchiver.load(key: LSLUser.Keys.token.rawValue) as? String
            let value = AccessTokenModel.deserialize(from: json)
            return value
        }
    }
    
    var refreshToken: AccessTokenModel? {
        set {
            guard let entity = newValue?.toJSONString() else { return }
            LocalArchiver.save(key: LSLUser.Keys.refreshToekn.rawValue, value: entity)
        }
        
        get {
            let json = LocalArchiver.load(key: LSLUser.Keys.refreshToekn.rawValue) as? String
            let value = AccessTokenModel.deserialize(from: json)
            return value
        }
    }
    
    var user: UserModel? {
        set {
            guard let entity = newValue?.toJSONString() else { return }
            changeableUserInfo.accept(newValue)
            LocalArchiver.save(key: LSLUser.Keys.userInfo.rawValue, value: entity)
            let shareUserDefault = UserDefaults(suiteName: ShareUserDefaultsKey.groupId.rawValue)
            shareUserDefault?.set(entity, forKey: ShareUserDefaultsKey.userInfo.rawValue)
            shareUserDefault?.synchronize()
        }
        
        get {
            let json = LocalArchiver.load(key: LSLUser.Keys.userInfo.rawValue) as? String
            let value = UserModel.deserialize(from: json)
            return value
        }
    }
    
    
    var scene: SceneListModel? {
        set {
            print("场景更新")
            changeableScene.accept(newValue)
            LocalArchiver.save(key: LSLUser.Keys.scene.rawValue, value: newValue?.toJSONString())
            let shareUserDefault = UserDefaults(suiteName: ShareUserDefaultsKey.groupId.rawValue)
            shareUserDefault?.set(newValue?.toJSONString(), forKey: ShareUserDefaultsKey.scene.rawValue)
            shareUserDefault?.synchronize()
        }
        
        get {
            let json = LocalArchiver.load(key: LSLUser.Keys.scene.rawValue) as? String
            let value = SceneListModel.deserialize(from: json)
            return value
        }
    }
    
    var lockInfo: LockModel? {
        set {
            print("门锁信息更新")
            LocalArchiver.save(key: LSLUser.Keys.smartLockInfo.rawValue, value: newValue?.toJSONString())
            let shareUserDefault = UserDefaults(suiteName: ShareUserDefaultsKey.groupId.rawValue)
            shareUserDefault?.set(newValue?.toJSONString(), forKey: ShareUserDefaultsKey.lockDevice.rawValue)
            shareUserDefault?.synchronize()
        }
        
        get {
            let json = LocalArchiver.load(key: LSLUser.Keys.smartLockInfo.rawValue) as? String
            let value = LockModel.deserialize(from: json)
            return value
        }
    }
    
    var hasVerificationLock: Bool {
        set {
            LocalArchiver.save(key: LSLUser.Keys.verificationLock.rawValue, value: newValue)
        }
        get {
            let value = LocalArchiver.load(key: LSLUser.Keys.verificationLock.rawValue) as? Bool
            return value ?? true
        }
    }
    
    var isFirstLogin: Bool {
        set {
            LocalArchiver.save(key: LSLUser.Keys.isFirstLogin.rawValue, value: newValue)
        }
        get {
            let value = LocalArchiver.load(key: LSLUser.Keys.isFirstLogin.rawValue) as? Bool
            return value ?? false
        }
    }
        
    var obUserInfo: Observable<UserModel?> {
        return changeableUserInfo.asObservable()
    }
    
    var obScene: Observable<SceneListModel?> {
        return changeableScene.asObservable()
    }
    
    var obIsLogin: Observable<Bool> {
        let hasUserInfo = changeableUserInfo.map { $0 != nil }
        return hasUserInfo
    }
    
    var isInstalledLock: Bool {
        guard let sceneModel = self.scene else {
            return false
        }
        return sceneModel.ladderLockId.isNotNilNotEmpty
    }
    
    var hasSiriShortcuts: Bool {
        set {
            LocalArchiver.save(key: LSLUser.Keys.siriShortcuts.rawValue, value: newValue)
        }
        
        get {
            let value = LocalArchiver.load(key: LSLUser.Keys.siriShortcuts.rawValue) as? Bool
            return value ?? false
        }
    }
    
    private let changeableUserInfo = BehaviorRelay<UserModel?>(value: nil)
    private let changeableScene = BehaviorRelay<SceneListModel?>(value: nil)
    private let changeableToken = BehaviorRelay<AccessTokenModel?>(value: nil)
}

/// 归档的Key
extension LSLUser {
    enum Keys: String, CaseIterable {
        case refreshToekn = "refreshToeknModel"
        case token = "tokenModel"
        case scene = "currentSceneModel"
        case userInfo = "userInfoModel"
        case smartLockInfo = "smartLockInfo"
        case siriShortcuts = "siriShortcuts"
        case bluetoothVolume = "bluetoothVolume"
        case verificationLock = "verificationLock"
        case isFirstLogin = "isFirstLogin"
    }
}

