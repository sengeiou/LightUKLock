//
//  TodayViewModel.swift
//  LSLWidget
//
//  Created by mugua on 2020/1/2.
//  Copyright © 2020 mugua. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Moya
import RxDataSources

final class TodayViewModel {
    
    typealias Section = SectionModel<String, UnlockRecordModel>
    
    var sceneName: Observable<String?> {
        let jsonStr = shareDefault?.string(forKey: ShareUserDefaultsKey.scene.rawValue)
        let model = SceneListModel.deserialize(from: jsonStr)
        return .just(model?.buildingName)
    }
    
    var currentPower: Observable<String?> {
        return _currentPower.asObservable()
    }
    
    var requestExecuting: Observable<Bool> {
        return _requestExecuting.asObservable()
    }
    
    var dataSource: Observable<[Section]> {
        return _dataSource.asObservable()
    }
    
    private let _dataSource = BehaviorRelay<[Section]>(value: [])
    private let shareDefault = UserDefaults(suiteName: ShareUserDefaultsKey.groupId.rawValue)
    private let network = MoyaProvider<TodayExtensionInterface>()
    private let _currentPower = BehaviorRelay<String?>(value: nil)
    private let _requestExecuting = BehaviorRelay<Bool>(value: false)
    
    init() {
        _requestExecuting.accept(true)
        network.request(.getLockCurrentInfoFromIOTPlatform) {[weak self] (result) in
            switch result {
            case let .success(response):
                print(response)
                //                guard let data = try? response.filter(statusCode: 200).mapJSON() else {
                //                    self?._currentPower.accept("暂时无法获取电池电量")
                //                    return
                //                }
                //                let json = data as? [String: Any]
                //                let value = json?["Data"] as? [String: Any]
                //                let model = IOTLockInfoModel.deserialize(from: value)
                //                if let p = model?.getPower() {
                self?._currentPower.accept("剩余电量: \(100)")
                //                }
                self?._requestExecuting.accept(false)
                
            case .failure:
                self?._currentPower.accept("暂时无法获取电池电量")
                self?._requestExecuting.accept(false)
            }
        }
        
        network.request(.getUnlockLog) {[weak self] (result) in
            switch result {
            case let .success(response):
                guard let data = try? response.filter(statusCode: 200).mapJSON() else {
                    return
                }
                let json = data as? [String: Any]
                let value = json?["Data"] as? [[String: Any]]
                if let valueArray = [UnlockRecordModel].deserialize(from: value) {
                    let array = valueArray.compactMap { $0 }.map { Section(model: "Today解锁记录", items: [$0]) }
                    self?._dataSource.accept(array)
                }
                
            case .failure:
                break
            }
        }
    }
}

