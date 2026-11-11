Pod::Spec.new do |s|
  s.name             = 'trydos_wallet'
  s.version          = '0.0.1'
  s.summary          = 'Trydos wallet — native AWS Face Liveness step.'
  s.description      = <<-DESC
Native half of the wallet's identity check: it presents the Amplify UI Face
Liveness challenge. Everything around it — sessions, credentials, the verdict —
stays in Dart.
                       DESC
  s.homepage         = 'https://gitlab.com/trydos_app/trydos_wallet'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Trydos' => 'dev@trydos.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'

  # Imposed by amplify-ui-swift-liveness. The host app's deployment target
  # must be at least this.
  s.platform = :ios, '14.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'

  # The Face Liveness component ships as a Swift package, not a pod. CocoaPods
  # cannot pull it, so the HOST app adds it once in Xcode:
  #
  #   File ▸ Add Package Dependencies…
  #   https://github.com/aws-amplify/amplify-ui-swift-liveness
  #
  # Until it is added, FACE_LIVENESS_AVAILABLE stays undefined and this plugin
  # reports the detector as unavailable rather than failing at runtime — see
  # FaceLivenessPresenter.swift.
end
