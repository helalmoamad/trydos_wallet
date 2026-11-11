import Foundation
import SwiftUI
import UIKit

#if canImport(FaceLiveness)
import FaceLiveness
import Amplify
import AWSPluginsCore
#endif

/// Presents the Amplify UI Face Liveness challenge full screen.
///
/// Full screen is not a layout preference. The challenge reads a sequence of
/// coloured lights reflected off the user's face, so shrinking it into a card
/// inside the app would dim that light and push the pass rate down. The app's
/// own design resumes either side of this screen.
///
/// The whole file is compiled against `canImport(FaceLiveness)`. The component
/// ships as a Swift package that CocoaPods cannot pull, so a host that has not
/// added it still builds — [isAvailable] simply answers false and the flow
/// says so up front instead of failing once the user has photographed their ID.
final class FaceLivenessPresenter {

    typealias CredentialsProvider =
        (@escaping (Result<[String: Any], Error>) -> Void) -> Void

    /// Whether the Face Liveness package is linked into this build.
    static var isAvailable: Bool {
        #if canImport(FaceLiveness)
        return true
        #else
        return false
        #endif
    }

    private let credentialsProvider: CredentialsProvider
    private let onFinished: (FaceLivenessOutcome) -> Void
    private weak var presented: UIViewController?

    /// Guards against reporting twice — the SDK can call completion and then
    /// the view can disappear, and Dart must hear exactly one answer.
    private var finished = false

    init(
        credentialsProvider: @escaping CredentialsProvider,
        onFinished: @escaping (FaceLivenessOutcome) -> Void
    ) {
        self.credentialsProvider = credentialsProvider
        self.onFinished = onFinished
    }

    func present(from host: UIViewController, sessionId: String, region: String) {
        #if canImport(FaceLiveness)
        let view = FaceLivenessDetectorView(
            sessionID: sessionId,
            region: region,
            credentialsProvider: AmplifyCredentialsAdapter(provider: credentialsProvider),
            isPresented: .constant(true),
            onCompletion: { [weak self] result in
                switch result {
                case .success:
                    self?.finish(.completed)
                case .failure(let error):
                    self?.finish(.failed(
                        code: Self.code(for: error),
                        message: String(describing: error)
                    ))
                }
            }
        )

        let controller = UIHostingController(rootView: view)
        controller.modalPresentationStyle = .fullScreen
        presented = controller
        host.present(controller, animated: true)
        #else
        finish(.failed(
            code: TrydosWalletPlugin.errorSetup,
            message: "The Face Liveness package is not linked into this app."
        ))
        #endif
    }

    private func finish(_ outcome: FaceLivenessOutcome) {
        guard !finished else { return }
        finished = true

        let report = { [weak self] in self?.onFinished(outcome) }
        if let presented = presented, presented.presentingViewController != nil {
            presented.dismiss(animated: true, completion: report)
        } else {
            report()
        }
    }

    #if canImport(FaceLiveness)
    /// Maps the SDK's failures onto the codes Dart branches on.
    private static func code(for error: Error) -> String {
        let text = String(describing: error).lowercased()
        if text.contains("landscape") { return TrydosWalletPlugin.errorLandscape }
        if text.contains("cancel") { return TrydosWalletPlugin.errorCancelled }
        if text.contains("camera") || text.contains("permission") {
            return TrydosWalletPlugin.errorCamera
        }
        return TrydosWalletPlugin.errorSetup
    }
    #endif
}

#if canImport(FaceLiveness)
/// Bridges the SDK's credentials request to Dart.
///
/// The temporary credentials never touch disk and are not cached here — the
/// SDK asks again when they lapse, and each ask makes a fresh fetch.
struct AmplifyCredentialsAdapter: AWSCredentialsProvider {

    let provider: FaceLivenessPresenter.CredentialsProvider

    func fetchAWSCredentials() async throws -> AWSCredentials {
        let map: [String: Any] = try await withCheckedThrowingContinuation { continuation in
            provider { result in
                continuation.resume(with: result)
            }
        }

        guard
            let accessKeyId = map["accessKeyId"] as? String, !accessKeyId.isEmpty,
            let secretAccessKey = map["secretAccessKey"] as? String, !secretAccessKey.isEmpty,
            let sessionToken = map["sessionToken"] as? String, !sessionToken.isEmpty
        else {
            throw FaceLivenessCredentialsError.rejected("Incomplete STS credentials.")
        }

        // An unparsable or absent expiry counts as already past, so the SDK
        // refreshes rather than trusting a lifetime we cannot vouch for.
        let expiration = (map["expiration"] as? String)
            .flatMap(ISO8601DateFormatter.parse) ?? Date()

        return AWSTemporaryCredentials(
            accessKeyId: accessKeyId,
            secretAccessKey: secretAccessKey,
            sessionToken: sessionToken,
            expiration: expiration
        )
    }
}

private extension ISO8601DateFormatter {
    /// The Worker sends fractional seconds; the default formatter rejects
    /// them, so both shapes are tried.
    static func parse(_ value: String) -> Date? {
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = withFraction.date(from: value) { return date }

        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return plain.date(from: value)
    }
}
#endif
