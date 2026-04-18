import Foundation
import FirebaseAuth
import AuthenticationServices
import CryptoKit

// MARK: - AuthState

enum AuthState: Equatable {
    case unknown
    case signedOut
    case anonymous(userId: String)
    case authenticated(userId: String, email: String?)

    static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.unknown, .unknown), (.signedOut, .signedOut):
            return true
        case let (.anonymous(l), .anonymous(r)):
            return l == r
        case let (.authenticated(lId, lEmail), .authenticated(rId, rEmail)):
            return lId == rId && lEmail == rEmail
        default:
            return false
        }
    }
}

// MARK: - AuthManager

@Observable
final class AuthManager: NSObject {
    private(set) var authState: AuthState = .unknown
    private var stateListenerHandle: AuthStateDidChangeListenerHandle?

    // Apple Sign-In continuation
    private var appleSignInContinuation: CheckedContinuation<ASAuthorization, Error>?
    private var currentNonce: String?

    var currentUserId: String? {
        switch authState {
        case .anonymous(let userId): return userId
        case .authenticated(let userId, _): return userId
        default: return nil
        }
    }

    var isAuthenticated: Bool {
        switch authState {
        case .anonymous, .authenticated: return true
        default: return false
        }
    }

    /// Whether the auth state listener has been attached yet.
    private var isListening = false

    // MARK: - Init

    override init() {
        super.init()
        // Don't call Auth.auth() here — Firebase may not be configured yet.
        // Call startListening() after FirebaseApp.configure().
    }

    /// Attaches the Firebase Auth state listener. Must be called after `FirebaseApp.configure()`.
    func startListening() {
        guard !isListening else { return }
        isListening = true
        stateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            self.updateAuthState(from: user)
        }
    }

    deinit {
        if let handle = stateListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    private func updateAuthState(from user: User?) {
        guard let user else {
            authState = .signedOut
            return
        }
        if user.isAnonymous {
            authState = .anonymous(userId: user.uid)
        } else {
            authState = .authenticated(userId: user.uid, email: user.email)
        }
    }

    // MARK: - Sign In Anonymously (Task 1.2)

    func signInAnonymously() async throws {
        let result = try await Auth.auth().signInAnonymously()
        authState = .anonymous(userId: result.user.uid)
    }

    // MARK: - Sign In with Apple (Task 1.4)

    func signInWithApple() async throws {
        let (credential, nonce) = try await requestAppleCredential()
        let oAuthCredential = OAuthProvider.appleCredential(
            withIDToken: credential.identityToken.flatMap { String(data: $0, encoding: .utf8) } ?? "",
            rawNonce: nonce,
            fullName: credential.fullName
        )
        let result = try await Auth.auth().signIn(with: oAuthCredential)
        updateAuthState(from: result.user)
    }

    // MARK: - Link Apple Credential (Task 1.5)

    func linkAppleCredential() async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw AuthManagerError.noCurrentUser
        }
        let (credential, nonce) = try await requestAppleCredential()
        let oAuthCredential = OAuthProvider.appleCredential(
            withIDToken: credential.identityToken.flatMap { String(data: $0, encoding: .utf8) } ?? "",
            rawNonce: nonce,
            fullName: credential.fullName
        )
        do {
            let result = try await currentUser.link(with: oAuthCredential)
            updateAuthState(from: result.user)
        } catch let error as NSError where error.code == AuthErrorCode.credentialAlreadyInUse.rawValue {
            throw AuthManagerError.credentialAlreadyInUse
        }
    }

    // MARK: - Sign Out (Task 1.6)

    func signOut() throws {
        try Auth.auth().signOut()
        UserDefaults.standard.removeObject(forKey: AvatarConfig.storageKey)
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        authState = .signedOut
    }

    // MARK: - Apple Sign-In Helpers

    private func requestAppleCredential() async throws -> (ASAuthorizationAppleIDCredential, String) {
        let nonce = randomNonceString()
        currentNonce = nonce
        let hashedNonce = sha256(nonce)

        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = hashedNonce

        let authorization = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ASAuthorization, Error>) in
            appleSignInContinuation = continuation
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.performRequests()
        }

        guard let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw AuthManagerError.invalidCredential
        }
        return (appleCredential, nonce)
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        guard errorCode == errSecSuccess else {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        appleSignInContinuation?.resume(returning: authorization)
        appleSignInContinuation = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        appleSignInContinuation?.resume(throwing: error)
        appleSignInContinuation = nil
    }
}

// MARK: - Errors

enum AuthManagerError: LocalizedError {
    case noCurrentUser
    case invalidCredential
    case credentialAlreadyInUse

    var errorDescription: String? {
        switch self {
        case .noCurrentUser:
            return "No user is currently signed in."
        case .invalidCredential:
            return "Failed to obtain a valid Apple credential."
        case .credentialAlreadyInUse:
            return "This Apple ID is already linked to another account."
        }
    }
}
