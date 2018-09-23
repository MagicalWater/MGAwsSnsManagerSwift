//
//  RawAwsSnsConfig.swift
//  MGAwsSnsManagerSwift
//
//  Created by Magical Water on 2018/9/19.
//  Copyright © 2018年 MagicalWater. All rights reserved.
//

import Foundation
import SwiftyJSON
import MGUtilsSwift

//反序列化 mgawssnsconfig.txt
class RawAwsSnsConfig: MGJsonDeserializeDelegate {
    
    var configMap: [String:AWSSNSTarget]!
    
    required init(_ json: JSON) {
        configMap = json.dictionaryValue.mapValues { AWSSNSTarget.init($0) }
    }
    
}

class AWSSNSTarget {
    
    var applicationArn: String!
    var topicsArn: [String]!
    var region: String!
    var identityPoolId: String!
    
    init(_ json: JSON) {
        applicationArn = json["applicationArn"].stringValue
        topicsArn = json["topicsArn"].arrayValue.map { $0.stringValue }
        region = json["region"].stringValue
        identityPoolId = json["identityPoolId"].stringValue
    }
    
}
