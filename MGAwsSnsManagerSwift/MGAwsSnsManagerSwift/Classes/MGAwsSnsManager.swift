//
//  MGAwsSnsManager.swift
//  MGAwsSnsManagerSwift
//
//  Created by Magical Water on 2018/9/19.
//  Copyright © 2018年 MagicalWater. All rights reserved.
//

import Foundation
import AWSCore
import AWSCognito
import AWSSNS
import UserNotifications

//aws的simple notification service封裝使用
//在此頁面會順便註冊遠程推播, 因此不須在AppDelegate再註冊一次
//在app入口點, 必須呼叫 configurationInit() 此方法初始化 Amazon Cognito 憑證提供程序
//func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
//  configurationInit()
//}
public class MGAwsSnsManager: NSObject {
    
    //依照專案是 release 或者 debug 設置字串, 此設定
    #if RELEASE
    let mAppType: String = "release";
    #else
    let mAppType: String = "debug";
    #endif
    
    //地區字串對應
    private let mRegionTypeMap: [String : AWSRegionType] = [
        "us-east-2"         : AWSRegionType.USEast2,        //美国东部（俄亥俄州）
        "us-east-1"         : AWSRegionType.USEast1,        //美国东部（弗吉尼亚北部）
        "us-west-1"         : AWSRegionType.USWest1,        //美国西部（加利福尼亚北部）
        "us-west-2"         : AWSRegionType.USWest2,        //美国西部（俄勒冈）
        "ap-south-1"        : AWSRegionType.APSouth1,       //亚太地区（孟买）
        "ap-northeast-2"    : AWSRegionType.APNortheast2,   //亚太区域（首尔）
        //        "ap-northeast-3"    : AWSRegionType.APNortheast3,   //亚太区域 (大阪当地)** 只能与 亚太区域（东京） 区域结合使用。要请求访问 亚太区域 (大阪当地) 区域，请联系您的销售代表。
        "ap-southeast-1"    : AWSRegionType.APSoutheast1,   //亚太区域（新加坡）
        "ap-southeast-2"    : AWSRegionType.APSoutheast2,   //亚太区域（悉尼）
        "ap-northeast-1"    : AWSRegionType.APNortheast1,   //亚太区域（东京）
        "ca-central-1"      : AWSRegionType.CACentral1,     //加拿大 (中部)
        "cn-north-1"        : AWSRegionType.CNNorth1,       //中国（北京）
        "cn-northwest-1"    : AWSRegionType.CNNorthWest1,   //中国 (宁夏)
        "eu-central-1"      : AWSRegionType.EUCentral1,     //欧洲（法兰克福）
        "eu-west-1"         : AWSRegionType.EUWest1,        //欧洲（爱尔兰）
        "eu-west-2"         : AWSRegionType.EUWest2,        //欧洲 (伦敦)
        "eu-west-3"         : AWSRegionType.EUWest3,        //欧洲 (巴黎)
        "sa-east-1"         : AWSRegionType.SAEast1         //南美洲（圣保罗）
    ]
    
    enum MGSNSError: Error {
        case noMatchRegion      //沒有對應到地區
        case noFoundConfigText  //沒有找到初始化配置文件
    }
    
    private(set) var mApplicationArn: String = ""
    private(set) var mTopicsArn: [String] = []
    private(set) var mRegion: String = ""
    private(set) var mIdentityPoolId: String = ""
    
    private var mSubScriptProtocol: String = "application"
    
    private(set) var mEndPoint: String = ""
    
    //app是否已經註冊了
    private var mIsAppArnRegistered: Bool = false
    
    //主題是否已經註冊了
    public private(set) var isTopicRegistered: Bool = false
    
    //依照此key在userdefault讀取是否有開啟主題推播
    private let keyForTopicRegistered = "keyForTopicRegistered"
    
    public static let shared: MGAwsSnsManager = MGAwsSnsManager.init()
    
    private override init() {
        super.init()
        self.loadSetting()
    }
    
    /*
     直接設定 awsconfig.txt, 內容需求見demo, awsconfig.txt位置在主包bundle裏
     */
    public func loadConfig(_ customConfigFileName: String? = nil) throws {
        let defultConfigFileName: String = "mgawssnsconfig.txt"
        let configName = customConfigFileName ?? defultConfigFileName
        
        
        if let path = Bundle.main.url(forResource: configName, withExtension: nil),
            let configText = try? String(contentsOf: path),
            let configData = configText.data(using: .utf8),
            let config = try? JSONDecoder().decode(RawAwsSnsConfig.self, from: configData) {
            let target = config.configMap[mAppType]!
            mApplicationArn = target.applicationArn
            mTopicsArn = target.topicsArn
            mRegion = target.region
            mIdentityPoolId = target.identityPoolId
        } else {
            throw MGSNSError.noFoundConfigText
        }
    }
    
    /*
     @param applicationArn: app 的 arn
     @param topicsArn: 需要訂閱的主題 arn
     @param regionType: 地區字串, 具體字串對應參考 http://docs.aws.amazon.com/general/latest/gr/rande.html
     @param identityPoolId: 身份池id
     */
    public func loadConfig(applicationArn: String, topicsArn: [String], region: String, identityPoolId: String) throws {
        mApplicationArn = applicationArn
        mTopicsArn = topicsArn
        mRegion = region
        mIdentityPoolId = identityPoolId
    }
    
    //將主題是否註冊了的設定寫入app
    private func saveSetting() {
        UserDefaults.standard.set(isTopicRegistered, forKey: keyForTopicRegistered)
        UserDefaults.standard.synchronize()
    }
    
    //取出app是否已經注冊主題
    private func loadSetting() {
        isTopicRegistered = UserDefaults.standard.bool(forKey: keyForTopicRegistered)
    }
    
    //將字串轉換為對應的地區
    private func convertRegionType(by string: String) throws -> AWSRegionType {
        if let region = mRegionTypeMap[string] {
            return region
        } else {
            throw MGSNSError.noMatchRegion
        }
    }
    
    //初始化 Amazon Cognito 憑證提供程序
    //此方法必須在 AppDelegate 入口點呼叫, 即是以下方法
    //func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?)
    public func settingStart() throws {
        let regionType = try convertRegionType(by: mRegion)
        
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: regionType,
                                                                identityPoolId: mIdentityPoolId)
        
        let configuration = AWSServiceConfiguration(region: regionType, credentialsProvider: credentialsProvider)
        
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        //在此註冊遠程推播
        registerAppNotificationSettings()
    }
    
    /*
     取得裝置token後, 需要向aws進行註冊, 同時在此處解析出token字串
     註冊endpoint到applicationArn裡面
     此方法必須在 AppDelegate 的以下方法呼叫
     func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
     
     @param deviceToken - app的裝置token
     @param autoRegisterTopic - 是否在app註冊成功後自動註冊topic
     */
    public func registerToApplication(deviceToken: Data, autoRegisterTopic: Bool) {
        var token = ""
        for i in 0..<deviceToken.count {
            token = token + String(format: "%02.2hhx", arguments: [deviceToken[i]])
        }
        
        print("裝置 token = \(token)")
        
        /// Create a platform endpoint. In this case,  the endpoint is a
        /// device endpoint ARN
        let sns = AWSSNS.default()
        let request = AWSSNSCreatePlatformEndpointInput()
        request?.token = token
        request?.platformApplicationArn = mApplicationArn
        
        sns.createPlatformEndpoint(request!).continueWith(executor: AWSExecutor.mainThread(), block: { [weak self] (task: AWSTask!) -> AnyObject? in
            if task.error != nil {
                print("aws 創建 endpoint 發生錯誤: \(String(describing: task.error))")
                self?.mEndPoint = ""
            } else {
                let createEndpointResponse = task.result! as AWSSNSCreateEndpointResponse
                
                if let endpointArnForSNS = createEndpointResponse.endpointArn {
                    self?.mEndPoint = endpointArnForSNS
                    print("aws 創建 endpoint 成功: \(endpointArnForSNS)")
                    if autoRegisterTopic {
                        self?.registerToTopic()
                    }
                } else {
                    self?.mEndPoint = ""
                    print("aws 創建 endpoint 成功: 但 endpoint 為空")
                }
            }
            
            return nil
        })
    }
    
    //取得 endPoint 並且註冊到 application 之後, 即可以開始註冊到 topic
    //不管訂閱是否成功, 都將已經開啟推播功能寫入專案
    public func registerToTopic() {
        isTopicRegistered = true
        saveSetting()
        
        if mTopicsArn.count == 0 {
            return
        }
        let sns = AWSSNS.default()
        mTopicsArn.forEach { topicArn in
            let subscriptInput = AWSSNSSubscribeInput.init()
            subscriptInput?.topicArn = topicArn
            subscriptInput?.protocols = mSubScriptProtocol
            subscriptInput?.endpoint = mEndPoint
            
            sns.subscribe(subscriptInput!) { (subscribeResponse, err) in
                if let err = err {
                    print("訂閱topic出錯: \(err)")
                } else if let response = subscribeResponse {
                    print("訂閱topic成功: \(String(describing: response.subscriptionArn))")
                }
            }
        }
    }
    
    //取消訂閱主題
    //不管取消訂閱是否成功, 都將已經關閉推播功能寫入專案
    public func unregisterTopic() {
        isTopicRegistered = false
        saveSetting()
        
        if mTopicsArn.count == 0 {
            return
        }
        let sns = AWSSNS.default()
        mTopicsArn.forEach { topicArn in
            let unsubscriptInput = AWSSNSUnsubscribeInput.init()
            unsubscriptInput?.subscriptionArn = topicArn
            
            sns.unsubscribe(unsubscriptInput!) { err in
                if let err = err {
                    print("取消訂閱topic出錯: \(err)")
                } else {
                    print("取消訂閱topic成功: \(topicArn)")
                }
            }
            
            
        }
    }
}

extension MGAwsSnsManager: UNUserNotificationCenterDelegate {
    //註冊推播
    public func registerAppNotificationSettings() {
        if #available(iOS 10.0, *) { //iOS10註冊通知
            let notifiCenter = UNUserNotificationCenter.current()
            notifiCenter.delegate = self
            let types = UNAuthorizationOptions(arrayLiteral: [.alert, .badge, .sound])
            notifiCenter.requestAuthorization(options: types) { (flag, error) in
                if flag {
                    print("推播 - iOS 10 註冊通知成功")
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
                else { print("推播 - iOS 10 註冊通知失敗") }
            }
        } else { //iOS8,iOS9註冊通知
            //指定支持的通知類型
            let notificationTypes: UIUserNotificationType = [UIUserNotificationType.alert, UIUserNotificationType.badge, UIUserNotificationType.sound]
            
            //創建通知設定的 instance: UIUserNotificationSettings
            let pushNotificationSettings = UIUserNotificationSettings.init(types: notificationTypes, categories: nil)
            
            //將以 pushNotificationSettings 為設定註冊推播
            UIApplication.shared.registerUserNotificationSettings(pushNotificationSettings)
            
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    //iOS10新增：處理前台收到通知得代理方法
    @available(iOS 10.0, *)
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void){
        let userInfo = notification.request.content.userInfo
        print("推播 - iOS 10: 前台接收遠程通知 - userInfo:\(userInfo)")
        completionHandler([.sound,.alert]) //此方法要求執行
        
    }
    
    //iOS10新增：處理後台點擊通知的代理方法, 用戶點擊推播時觸發, 如果用戶長案(3D Touch)/彈出Action頁面不會觸發, 點擊Action時會觸發
    @available(iOS 10.0, *)
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void){
        let userInfo = response.notification.request.content.userInfo
        print("推播 - iOS 10: 後台接收遠程通知 - userInfo:\(userInfo)")
        completionHandler() //此方法要求執行
        
    }
    
}
