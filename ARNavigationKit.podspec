Pod::Spec.new do |s|

# 1
s.platform = :ios
s.ios.deployment_target = '12.0'
s.name = "ARNavigationKit"
s.summary = "ARNavigationKit provides robust indoor navigation."
s.requires_arc = true

# 2
s.version = "1.0.0"

# 3
s.license = { :type => "MIT", :file => "LICENSE" }

# 4 - Replace with your name and e-mail address
s.author = { "Ferdinand Losch" => "ferdinandloesch@me.com" }

# 5 - Replace this URL with your own GitHub page's URL (from the address bar)
s.homepage = "https://github.com/ferdinandl007/ARNavigationKit"

# 6 - Replace this URL with your own Git URL from "Quick Setup"
s.source = { :git => "https://github.com/ferdinandl007/ARNavigationKit.git",
             :tag => "#{s.version}" }

# 7
s.framework = "UIKit"
s.framework = "Foundation"
s.framework = "GameplayKit"
s.framework = "simd"
s.framework = "ARKit"


# 8
s.source_files = "ARNavigationKit/**/*.{swift}"

# 9
#s.resources = "ARNavigationKit/**/*.{png,jpeg,jpg,storyboard,xib,xcassets}"

# 10
s.swift_version = "5.0"

end
