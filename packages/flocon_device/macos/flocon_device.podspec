#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flocon_device.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flocon_device'
  s.version          = '0.0.1'
  s.summary          = 'Device plugin for Flocon'
  s.description      = <<-DESC
Sends the app icon to the Flocon desktop app.
                       DESC
  s.homepage         = 'https://github.com/openflocon/FloconFlutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Flocon' => 'noreply@example.com' }

  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'

  # If your plugin requires a privacy manifest, for example if it collects user
  # data, update the PrivacyInfo.xcprivacy file to describe your plugin's
  # privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'flocon_device_privacy' => ['Resources/PrivacyInfo.xcprivacy']}

  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
