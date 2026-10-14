/// The ordered FinEcho onboarding steps.
enum OnboardingStep {
  /// Explains local-only financial storage.
  privacy,

  /// Explains local voice-entry behavior.
  voiceLogging,

  /// Explains optional Android SMS automation.
  automation,

  /// Collects the app-lock fallback preference.
  securitySetup,
}
