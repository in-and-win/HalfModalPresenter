#
#  Be sure to run `pod spec lint HalfModalPresenter.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|
  s.name         = "HalfModalPresenter"
  s.version      = "0.0.1"
  s.summary      = "Presents a modal when a click is triggered on a UIView"
  s.description  = <<-DESC
  Simple modal presenter that can be easily customized (It just shows a UIView)
                   DESC
  s.homepage     = "https://github.com/in-and-win/HalfModalPresenter.git"

  s.license      = "MIT"

  s.authors            = { "raphaelbischof" => "raphael.bischof@gmail.com", "In And Win" => "tech-mobile@in-and-win.com" }
  s.social_media_url   = "http://twitter.com/rbische"

  s.platform     = :ios, "8.0"

  s.source       = { :git => "https://github.com/in-and-win/HalfModalPresenter.git", :tag => "#{s.version}" }

  s.source_files = 'Source/*.swift'

  s.requires_arc = true

end
