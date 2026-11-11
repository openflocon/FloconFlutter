#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flocon.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flocon'
  s.version          = '0.0.1'
  s.summary          = 'Device plugin for Flocon'
  s.description      = <<-DESC
Sends the app icon to the Flocon desktop app.
                       DESC
  s.homepage         = 'https://github.com/openflocon/FloconFlutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Flocon' => 'noreply@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'flocon/Sources/flocon/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  s.resource_bundles = {'flocon_privacy' => ['flocon/Sources/flocon/Resources/PrivacyInfo.xcprivacy']}
end
