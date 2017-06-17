Pod::Spec.new do |s|
  
  s.name         = "GreendeckiOSSDK"
  s.version      = "1.0.0"
  s.summary      = "iOS SDK for Greendeck; for more info visit greendeck.co"
  s.description  = "iOS SDK for Greendeck; for more info visit greendeck.co"

  s.homepage     = "http://www.greendeck.co"

  s.license      = "MIT"
  s.author       = { "Yashvardhan Srivastava" => "yash@greendeck.co" }
  
  s.platform     = :ios, "9.0"
  
  s.source       = { :path => '.' }
  s.source_files = s.source_files = "GreendeckiOSSDK", "GreendeckiOSSDK/**/*.{h,m,swift}"
  
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '3' }

end
