Pod::Spec.new do |s|
  s.name             = 'SegmentedSlider'
  s.version          = '1.1.1'
  s.summary          = 'A customizable control to select a value from continuous range of values.'
  s.description      = <<-DESC
SegmentedSlider is a customizable slider that renders it's range as a sequence of sections divided into segments. 
It scrolls it's background instead of moving the central handle. Supports interface builder and designed to be 
similar with UISlider in it's API.
                       DESC
  s.homepage         = 'https://github.com/vahan3x/SegmentedSlider'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Vahan Babayan' => 'vahan3x@gmail.com' }
  s.source           = { :git => 'https://github.com/vahan3x/SegmentedSlider.git', :tag => s.version.to_s }
  s.ios.deployment_target = '10.0'
  s.swift_version = '4.2'
  s.source_files = 'SegmentedSlider/**/*.swift'
  s.frameworks = 'UIKit'
end
