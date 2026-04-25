import Foundation

/// Persists the "user has completed onboarding" flag in UserDefaults.
public enum OnboardingState {
    private static let key = "MacCleanerPro.hasCompletedOnboarding"

    public static var hasCompleted: Bool {
        get { UserDefaults.standard.bool(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }

    public static func reset() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
