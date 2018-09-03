#
#  Be sure to run `pod spec lint FirebaseModel.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.name         = "FirebaseModel"
  s.version      = "0.0.1"
  s.summary      = "A short description of FirebaseModel."
  s.description  = "The ultimate Active Record pattern for Firebase"
  s.homepage     = "http://www.sportsanalyticsinc.com"
  s.author             = { "Miroslav Kutak" => "kutakmiroslav@gmail.com" }
  s.source       = { :git => "https://https://github.com/kutakmir/FirebaseModel.git", :tag => "#{s.version}" }
  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.source_files  = "Classes", "Classes/**/*.{h,m,swift}"
  s.exclude_files = "Classes/Exclude"
  s.public_header_files = "Classes/**/*.h"
  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  # s.resources = "Resources/*.png"
  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.dependency "FirebaseDatabase"
  s.dependency "FirebaseAuth"
  s.dependency "FirebaseFirestore"

end
