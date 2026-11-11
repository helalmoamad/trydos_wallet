import Flutter
import UIKit

/// Native half of the AWS Face Liveness step on iOS.
///
/// Dart drives the flow — KYC session, AWS session, verdict. This side only
/// presents the Amplify UI challenge full screen and reports whether it ran.
///
/// It is given no token and no Worker URL: when the SDK needs credentials the
/// request goes back over the channel and Dart fetches them.
public class TrydosWalletPlugin: NSObject, FlutterPlugin {

    private static let channelName = "trydos_wallet/face_liveness"

    static let errorSetup = "SETUP_FAILED"
    static let errorCancelled = "CANCELLED"
    static let errorCamera = "CAMERA_PERMISSION"
    static let errorLandscape = "LANDSCAPE"

    private let channel: FlutterMethodChannel

    /// Pending `present` call. Answered once, when the challenge ends.
    private var pendingResult: FlutterResult?

    private var presenter: FaceLivenessPresenter?

    init(channel: FlutterMethodChannel) {
        self.channel = channel
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: registrar.messenger()
        )
        let instance = TrydosWalletPlugin(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isAvailable":
            result(FaceLivenessPresenter.isAvailable)

        case "present":
            present(call, result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func present(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard FaceLivenessPresenter.isAvailable else {
            result(FlutterError(
                code: Self.errorSetup,
                message: "The Face Liveness package is not linked into this app.",
                details: nil
            ))
            return
        }

        guard pendingResult == nil else {
            result(FlutterError(
                code: Self.errorSetup,
                message: "A liveness challenge is already running.",
                details: nil
            ))
            return
        }

        guard
            let args = call.arguments as? [String: Any],
            let sessionId = args["sessionId"] as? String, !sessionId.isEmpty,
            let region = args["region"] as? String, !region.isEmpty
        else {
            result(FlutterError(
                code: Self.errorSetup,
                message: "sessionId and region are required.",
                details: nil
            ))
            return
        }

        guard let host = Self.topViewController() else {
            result(FlutterError(
                code: Self.errorSetup,
                message: "No view controller to present the challenge on.",
                details: nil
            ))
            return
        }

        pendingResult = result
        let presenter = FaceLivenessPresenter(
            credentialsProvider: { [weak self] completion in
                self?.fetchCredentials(completion) ?? completion(
                    .failure(FaceLivenessCredentialsError.unavailable)
                )
            },
            onFinished: { [weak self] outcome in
                self?.finish(outcome)
            }
        )
        self.presenter = presenter
        presenter.present(from: host, sessionId: sessionId, region: region)
    }

    private func finish(_ outcome: FaceLivenessOutcome) {
        guard let pending = pendingResult else { return }
        pendingResult = nil
        presenter = nil

        switch outcome {
        case .completed:
            // The challenge ran. Pass or fail is AWS's verdict, which Dart
            // reads from the server — never decided here.
            pending(nil)
        case .failed(let code, let message):
            pending(FlutterError(code: code, message: message, details: nil))
        }
    }

    /// Asks Dart for fresh STS credentials.
    ///
    /// The SDK may call this more than once: the ~900 s window can close
    /// mid-challenge.
    private func fetchCredentials(
        _ completion: @escaping (Result<[String: Any], Error>) -> Void
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                completion(.failure(FaceLivenessCredentialsError.unavailable))
                return
            }
            self.channel.invokeMethod("getCredentials", arguments: nil) { response in
                if let error = response as? FlutterError {
                    completion(.failure(FaceLivenessCredentialsError.rejected(
                        error.message ?? error.code
                    )))
                    return
                }
                guard let map = response as? [String: Any] else {
                    completion(.failure(FaceLivenessCredentialsError.rejected(
                        "Credentials provider returned nothing usable."
                    )))
                    return
                }
                completion(.success(map))
            }
        }
    }

    /// The controller currently on screen, so the challenge is presented over
    /// the Flutter view rather than under it.
    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }

        let root = scene?.windows.first(where: { $0.isKeyWindow })?.rootViewController
            ?? UIApplication.shared.delegate?.window??.rootViewController

        var top = root
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}

/// Why the credentials hand-off failed.
enum FaceLivenessCredentialsError: Error {
    case unavailable
    case rejected(String)
}

/// How one challenge ended.
enum FaceLivenessOutcome {
    /// Ran to the end. Says nothing about whether the person passed.
    case completed
    case failed(code: String, message: String)
}
