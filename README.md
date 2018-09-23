# MGAwsSnsManagerSwift
![](https://img.shields.io/cocoapods/v/MGAWSSNSManagerSwift.svg?style=flat) 
![](https://img.shields.io/badge/platform-ios-lightgrey.svg) 
![](https://img.shields.io/badge/language-swift-orange.svg)

由於目前 aws 官方上面的文件講解不太完全, 且也沒太多相關的教學以及經驗分享,  
在接入 simple notification service 推播服務時遇到不小的困難,   
因此這邊整理了所有的步驟, 並且封裝成lib方便接入  

接入方式參考:  
[iOS Push with Amazon's AWS Simple Notifications Service (SNS)](https://medium.com/@thabodavidnyakalloklass/ios-push-with-amazons-aws-simple-notifications-service-sns-and-swift-made-easy-51d6c79bc206)  

## 版本
0.0.2 - 修改顯示名稱    
0.0.1 - 初始專案提交  

## 添加依賴  

### Cocoapods  
pod 'MGAwsSnsManagerSwift', '~> {version}'  
( 其中 {version} 請自行替入此版號 ![](https://img.shields.io/cocoapods/v/MGAWSSNSManagerSwift.svg?style=flat) )  

## 前置準備  
1. 專案的推播權限/憑證, 以及之後生成的 p12 文件, 由於教學較多, 不多做贅述
2. 專案配置遠程推播相關設定, 開啟 background mode, 以及 push notification
3. 專案引入 aws sdk, 可使用 cocoapods 直接引入, 當前文件使用的 sdk 版本皆為 2.6.29

        pod 'AWSCore', '~> 2.6.29'
        pod 'AWSSNS', '~> 2.6.29'
        pod 'AWSCognito', '~> 2.6.29'

## 初次接入 AWS Simple Notification Service
### 接入 aws sns 需要下列資料
1. **applicationArn - app arn**
2. **topicsArn - 訂閱主題(不一定需要)**
3. **region - 地區代碼**
4. **identityPoolId - 身份池id**

### 依照下列步驟可以得到上述所有資訊
1. 開啟 aws 的 sns 頁面, 選擇創建應用程序, 並且依照平台加入相關資訊, **在此步驟結束後可以得到 1. applicationArn**
2. 若不需要訂閱 topic(主題), 則跳過此步驟
    選擇創建主題, 輸入並創建 主題名稱, 顯示名稱(主要用於sms, 我們是接入sns可以不輸入), **在此步驟結束後可以得到 2. topicsArn**
2. 到 aws 控制台頁面, 點選服務搜索 cognito 並進入, 此處為創建 身份池(IdentityPool)的地方
3. 選擇 管理身份池, 選擇 創建新的身份池
4. 輸入 身份池名稱, 並勾選 启用未经验证的身份的访问权限, 接著點選 創建池, 選擇 允許
5. 在 demo 可以看到 身份池id(IdentityPoolId), **在此步驟可以得到 4. identityPoolId**
6. identityPoolId 的開頭字串(冒號之前), 即是 region(地區代碼), **在此步驟可以得到 3. region**
7. 接入aws sns所需資料皆已得到, 但仍需要設定身分池權限才可以使用, 因此請繼續往下完成 設置身分池權限

### 設置身分池權限
1. 回到 aws 控制台頁面, 點選服務搜索 IAM 並進入, 此為權限管理
2. 選擇 角色, 會看到 **Cognito_{剛才創建的身份池名稱}IdentityPoolAuth_Role** 和 **Cognito_{剛才創建的身份池名稱}IdentityPoolUnauth_Role**
3. 選擇 **Cognito_{剛才創建的身份池名稱}IdentityPoolUnauth_Role** 並進入
4. 選擇 權限, 選擇 附加策略, 搜索並加入 AmazonSNSFullAccess
5. 所有準備工作完成, 可以準備在專案裡面接入

## 在專案使用 MGAwsSnsManager 接入 aws sns 服務
1. 加入宏定義, 參考 [MGMacroDefinitionXcode](https://github.com/MagicalWater/MGMacroDefinitionXcode/blob/master/README.md),  
在 Release 加入 -DRELEASE
2. AppDelegate.swift 加入如下
    
        import MGAwsSnsManagerSwift

        @UIApplicationMain
        class AppDelegate: UIResponder, UIApplicationDelegate {

            //aws sns推播服務封裝類別
            private var mAwsManager: MGAwsSnsManager! 

            func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
                
                //推播初始化類別, 並初始化配置
                do {
                    //有兩種初始化選擇, 選擇一個進行初始化
                    //a. 無參數 - 須先在專案目錄下創建並加入名為 mgawssnsconfig.txt 的文件, 內容可參考最下方說明, 沒有或者內容不對則拋出錯誤
                    mAwsManager = try MGAwsSnsManager.init()
                    
                    //b. 有參數 - 帶入需要的資料
                    mAwsManager = MGAwsSnsManager.init(
                                        applicationArn: "",
                                        topicsArn: [],
                                        region: "",
                                        identityPoolId: ""
                                  )
                                  
                    //最後初始化相關配置, 此步驟會依據初始化時代入的資料設定 aws 身份憑證, 並且向系統註冊遠程推播
                    try mAwsManager.configurationInit()
                } catch {
                    print("初始化 awsManager 設置出現錯誤 \(error)")
                }
                
                return true
            }
        }
        
        //當向系統註冊遠程推播成功後調用
        func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
            //註冊 app token 到 aws app arn 下, 同時註冊 topic
            mAwsManager.registerToApplication(deviceToken: deviceToken)
        }
        
mgawssnsconfig.txt 的內容格式: [Config配置](https://github.com/MagicalWater/MGAwsSnsManagerSwift/blob/master/MGAwsSnsManagerSwift/MGAwsSnsManagerSwift/Classes/mgawssnsconfig.txt)
        
 3. 至此 aws 配置完成, 可以執行app看看了(當然不能是模擬器, 要實機)  
 若一切無誤的話, 可以在 sns app arn 點進去之後可以看到註冊的裝置, topic 同理
        
