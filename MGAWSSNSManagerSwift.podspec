Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.name         = "MGAWSSNSManagerSwift"
  s.version      = "0.0.2"
  s.summary      = "封裝使用 aws 的 simple notification service."

  s.description  = <<-DESC
由於目前 aws 官方上面的文件講解不太完全, 因此在接入 simple notification service 推播服務時遇到較大的困難, 這邊從頭到尾將接入的方式記錄下來, 並且封裝了接入的code方便使用
                   DESC

  s.homepage     = "https://github.com/MagicalWater/MGAwsSnsManagerSwift"
  
  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.license      = { :type => "MIT", :file => "LICENSE" }

  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.author             = { "MagicalWater" => "crazydennies@gmail.com" }

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.platform     = :ios, "9.0"

  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.source       = { :git => "https://github.com/MagicalWater/MGAwsSnsManagerSwift.git", :tag => "#{s.version}" }

  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.source_files  = "MGAwsSnsManagerSwift/MGAwsSnsManagerSwift/Classes/*.{swift}"

  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.resource  = "MGAwsSnsManagerSwift/MGAwsSnsManagerSwift/Classes/mgawssnsconfig.txt"

  # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.frameworks  = "Foundation", "UserNotifications"

  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  # s.dependency "JSONKit", "~> 1.4"
  s.dependency 'AWSCore', '~> 2.6.29'
  s.dependency 'AWSSNS', '~> 2.6.29'
  s.dependency 'AWSCognito', '~> 2.6.29'
  s.dependency 'MGUtilsSwift'

end
