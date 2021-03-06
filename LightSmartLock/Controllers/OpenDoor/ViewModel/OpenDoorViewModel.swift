//
//  OpenDoorViewModel.swift
//  LightSmartLock
//
//  Created by mugua on 2019/11/29.
//  Copyright © 2019 mugua. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import PKHUD
import SwiftDate

final class OpenDoorViewModel {
    
    var startConnected: Observable<Bool> {
        return obConnected.asObserver()
    }
    private let timer = Observable<Int>.timer(.seconds(0), period: .seconds(1), scheduler: MainScheduler.instance).share(replay: 1, scope: .forever)
    private let disposeBag = DisposeBag()
    private let obConnected = BehaviorSubject<Bool>(value: BluetoothPapa.shareInstance.isConnected())
    
    deinit {
        BluetoothPapa.shareInstance.scanForPeripherals(false)
    }
    
    init() {
       
        BluetoothPapa.shareInstance.checkBluetoothState { (state) in
            if state == .poweredOff {
                HUD.flash(.label("检测到蓝牙处于关闭状态\n请先开启蓝牙"), delay: 2)
            }
        }
        
        BluetoothPapa.shareInstance.scanForPeripherals(true)
        
        timer.take(10).subscribe(onNext: {[weak self] (_) in
            
            if BluetoothPapa.shareInstance.isConnected() {
                self?.obConnected.onNext(true)
                self?.obConnected.onCompleted()
            }
        }, onCompleted: {[weak self] in
            if BluetoothPapa.shareInstance.isConnected() {
                self?.obConnected.onNext(true)
                self?.obConnected.onCompleted()
            } else {
                self?.obConnected.onError(AppError.reason("没有找到蓝牙门锁"))
            }
        }).disposed(by: disposeBag)
        
        BluetoothPapa.shareInstance.peripheralsScanResult { (peripherals) in
            guard let peripheral = peripherals.last else {
                return
            }
            if BluetoothPapa.shareInstance.isConnected() {
                return
            }
            BluetoothPapa.shareInstance.connect(peripheral: peripheral)
        }
    }
    
    func openDoor() -> Observable<Bool> {
        
        return Observable<Bool>.create { (observer) -> Disposable in
            BluetoothPapa.shareInstance.openDoor { (res) in
                let success = BluetoothPapa.serializeOpenDoor(res)
                if success {
                    observer.onNext(true)
                    observer.onCompleted()
                } else {
                    observer.onNext(false)
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }
    
    func uploadUnlockRecord() -> Observable<Bool> {
        guard let lockId = LSLUser.current().scene?.ladderLockId else {
            return .error(AppError.reason("无法获取门锁Id"))
        }
        let time = Date().toFormat("yyyy-MM-dd HH:mm:ss")
        
        return BusinessAPI.requestMapBool(.uploadOpenDoorRecord(lockId: lockId, time: time, type: 1))
    }
}
