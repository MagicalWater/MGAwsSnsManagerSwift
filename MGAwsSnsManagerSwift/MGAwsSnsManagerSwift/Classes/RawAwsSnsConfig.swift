//
//  RawAwsSnsConfig.swift
//  MGAwsSnsManagerSwift
//
//  Created by Magical Water on 2018/9/19.
//  Copyright © 2018年 MagicalWater. All rights reserved.
//

import Foundation

//反序列化 mgawssnsconfig.txt
class RawAwsSnsConfig: Codable {
    
    var configMap: [String:AWSSNSTarget]
    
}

class AWSSNSTarget: Codable {
    
    var applicationArn: String
    var topicsArn: [String]
    var region: String
    var identityPoolId: String
    
}
