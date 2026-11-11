import Foundation

struct TranscriptAccumulator {
  private var committed = ""
  private(set) var transcript = ""

  // Recent iOS versions restart formattedString after a pause, older ones keep it cumulative: both are handled.
  mutating func add(_ utterance: String, utteranceEnded: Bool) -> String {
    if committed.isEmpty || utterance.hasPrefix(committed) {
      transcript = utterance
    } else if utterance.isEmpty {
      transcript = committed
    } else {
      transcript = "\(committed) \(utterance)"
    }
    if utteranceEnded { committed = transcript }
    return transcript
  }
}
