//
//  Request.swift
//  GCDGroup
//
//  Created by iOS on 2018/10/28.
//  Copyright © 2018年 weiman. All rights reserved.
//

import Moya

enum Api {
    
    static let request: MoyaProvider<ApiService> = MoyaProvider()
}

enum ApiService {
    
    /// 第一个请求
    case firstRequest
    /// 第二个请求
    case secondRequest
    /// 第三个请求
    case thirdRequest
}

extension ApiService: TargetType {
    
    var baseURL: URL {
        return URL(string: "http://www.mocky.io")!
    }
    
    var path: String {
        
        switch self {
        case .firstRequest:
            return "/v2/5bd56863310000660041dae3"
        case .secondRequest:
            return "/v2/5bd568fe3100006e0041dae4"
        case .thirdRequest:
            return "/v2/5bd56a173100004b0041dae6"
        }
    }
    
    var method: Method {
        return .get
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        return .requestPlain
    }
    
    var headers: [String : String]? {
        return ["version": "1.0", "name": "这是一个测试"]
    }
    
}

