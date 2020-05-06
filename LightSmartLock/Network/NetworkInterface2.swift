//
//  NetworkInterface.swift
//  LightSmartLock
//
//  Created by mugua on 2019/11/20.
//  Copyright © 2019 mugua. All rights reserved.
//

import Foundation
import UIKit
import HandyJSON
import Moya

enum BusinessInterface2 {
    
    // 资产合同列表
    case getAssetContract(assetId: String, year: String)
    
    // 房东获取资产下的合同列表及账单列表
    case getAssetContracts(assetId: String)
    
    
    
}


extension BusinessInterface2: TargetType {
    
    var baseURL: URL {
        return URL(string: ServerHost.shared.environment.host)!
    }
    
    var headers: [String : String]? {
        guard let entiy = LSLUser.current().token else { return nil }
        
        guard let token = entiy.accessToken, let type = entiy.tokenType else {
            return nil
        }
        return ["Authorization": type + token]
    }
    
    var method: Moya.Method {
        switch self {
        case .getAssetContract,
             .getAssetContracts:
            
            return .get
        }
    }
    
    var path: String {
        switch self {
        case .getAssetContract:
            return "/tenant_contract_info/asset_contract"
        case .getAssetContracts:
            return "/tenant_contract_info/asset_contracts"
            
        }
    }
    
    var sampleData: Data {
        switch self {
        default:
            return Data()
        }
    }
    
    var task: Task {
        switch self {
        case .getAssetContract(assetId: let assetId, year: let year):
            let param = ["assetId": assetId,
                         "year": year]
            return .requestParameters(parameters: param, encoding: URLEncoding.queryString)
            
        case .getAssetContracts(assetId: let assetId):
            return .requestParameters(parameters: ["assetId": assetId], encoding: URLEncoding.queryString)
        }
    }
}
