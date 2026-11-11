import Foundation

enum SpeechErrorOutcome {
  case noSpeech
  case error(code: String, message: String)
}

enum SpeechErrorMapper {
  private static let audioDomains: Set<String> = [NSOSStatusErrorDomain, "AVFoundationErrorDomain"]

  static func map(_ error: Error) -> SpeechErrorOutcome {
    let nsError = error as NSError

    switch (nsError.domain, nsError.code) {
    case ("kAFAssistantErrorDomain", 1110):
      return .noSpeech
    case ("kAFAssistantErrorDomain", 203):
      return .error(code: "REQUEST_FAILED", message: "Speech recognition failed")
    case ("kAFAssistantErrorDomain", 1100):
      return .error(code: "RECOGNIZER_BUSY", message: "Recognizer busy")
    case ("kAFAssistantErrorDomain", 1101), ("kAFAssistantErrorDomain", 1107):
      return .error(code: "NOT_AVAILABLE", message: "Speech recognition service unavailable")
    case ("kAFAssistantErrorDomain", 1700):
      return .error(code: "PERMISSION_DENIED", message: "Insufficient permissions")
    case ("kLSRErrorDomain", 1):
      return .error(code: "PERMISSION_DENIED", message: "Insufficient permissions")
    case ("kLSRErrorDomain", 2):
      return .error(code: "NOT_AVAILABLE", message: "Speech recognizer not available")
    case ("kLSRErrorDomain", 4):
      return .error(code: "NETWORK_ERROR", message: "Network error")
    case ("kLSRErrorDomain", 7):
      return .error(code: "RECOGNIZER_BUSY", message: "Recognizer busy")
    default:
      break
    }

    if audioDomains.contains(nsError.domain) {
      return .error(code: "AUDIO_ERROR", message: "Audio recording error")
    }

    return .error(code: "UNKNOWN_ERROR", message: "Unknown error (\(nsError.domain) \(nsError.code))")
  }
}
