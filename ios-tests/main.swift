import Foundation

func then_equal(_ actual: String, _ expected: String, _ name: String) {
  guard actual == expected else {
    print("FAIL \(name): expected \"\(expected)\", got \"\(actual)\"")
    exit(1)
  }
  print("ok \(name)")
}

func test_keepsEarlierUtterance_whenRecognizerRestartsAfterPause() {
  var accumulator = TranscriptAccumulator()
  _ = accumulator.add("Hello", utteranceEnded: false)
  _ = accumulator.add("Hello world", utteranceEnded: true)
  _ = accumulator.add("How", utteranceEnded: false)

  let actual = accumulator.add("How are you", utteranceEnded: false)

  then_equal(actual, "Hello world How are you", #function)
}

func test_doesNotDuplicate_whenRecognizerKeepsCumulativeText() {
  var accumulator = TranscriptAccumulator()
  _ = accumulator.add("Hello world", utteranceEnded: true)

  let actual = accumulator.add("Hello world how are you", utteranceEnded: false)

  then_equal(actual, "Hello world how are you", #function)
}

func test_replacesRevisedPartials_withinOneUtterance() {
  var accumulator = TranscriptAccumulator()
  _ = accumulator.add("I scream", utteranceEnded: false)

  let actual = accumulator.add("Ice cream", utteranceEnded: false)

  then_equal(actual, "Ice cream", #function)
}

func test_keepsEveryUtterance_acrossSeveralPauses() {
  var accumulator = TranscriptAccumulator()
  _ = accumulator.add("One", utteranceEnded: true)
  _ = accumulator.add("Two", utteranceEnded: true)

  let actual = accumulator.add("Three", utteranceEnded: false)

  then_equal(actual, "One Two Three", #function)
}

func test_keepsCommittedText_whenNewUtteranceIsEmpty() {
  var accumulator = TranscriptAccumulator()
  _ = accumulator.add("Hello", utteranceEnded: true)

  let actual = accumulator.add("", utteranceEnded: false)

  then_equal(actual, "Hello", #function)
}

func when_mapping(_ domain: String, _ code: Int) -> SpeechErrorOutcome {
  SpeechErrorMapper.map(NSError(domain: domain, code: code))
}

func then_reportsError(_ actual: SpeechErrorOutcome, _ expectedCode: String, _ name: String) {
  guard case let .error(code, _) = actual else {
    print("FAIL \(name): expected error \(expectedCode), got \(actual)")
    exit(1)
  }
  then_equal(code, expectedCode, name)
}

func test_endsSessionSilently_whenNoSpeechIsDetected() {
  let actual = when_mapping("kAFAssistantErrorDomain", 1110)

  guard case .noSpeech = actual else {
    print("FAIL \(#function): expected noSpeech, got \(actual)")
    exit(1)
  }
  print("ok \(#function)")
}

func test_mapsAssistantErrors_toExistingCodes() {
  then_reportsError(when_mapping("kAFAssistantErrorDomain", 203), "REQUEST_FAILED", "\(#function) 203")
  then_reportsError(when_mapping("kAFAssistantErrorDomain", 1100), "RECOGNIZER_BUSY", "\(#function) 1100")
  then_reportsError(when_mapping("kAFAssistantErrorDomain", 1101), "NOT_AVAILABLE", "\(#function) 1101")
  then_reportsError(when_mapping("kAFAssistantErrorDomain", 1107), "NOT_AVAILABLE", "\(#function) 1107")
  then_reportsError(when_mapping("kAFAssistantErrorDomain", 1700), "PERMISSION_DENIED", "\(#function) 1700")
}

func test_keepsExistingLocalRecognizerMapping() {
  then_reportsError(when_mapping("kLSRErrorDomain", 4), "NETWORK_ERROR", #function)
}

func test_mapsAudioDomains_toAudioError() {
  then_reportsError(when_mapping("AVFoundationErrorDomain", -11800), "AUDIO_ERROR", #function)
}

func test_exposesNativeDomainAndCode_whenErrorIsUnmapped() {
  let actual = when_mapping("kAFAssistantErrorDomain", 9999)

  guard case let .error(code, message) = actual else {
    print("FAIL \(#function): expected error, got \(actual)")
    exit(1)
  }
  then_equal(code, "UNKNOWN_ERROR", "\(#function) code")
  then_equal(message, "Unknown error (kAFAssistantErrorDomain 9999)", "\(#function) message")
}

test_keepsEarlierUtterance_whenRecognizerRestartsAfterPause()
test_doesNotDuplicate_whenRecognizerKeepsCumulativeText()
test_replacesRevisedPartials_withinOneUtterance()
test_keepsEveryUtterance_acrossSeveralPauses()
test_keepsCommittedText_whenNewUtteranceIsEmpty()
test_endsSessionSilently_whenNoSpeechIsDetected()
test_mapsAssistantErrors_toExistingCodes()
test_keepsExistingLocalRecognizerMapping()
test_mapsAudioDomains_toAudioError()
test_exposesNativeDomainAndCode_whenErrorIsUnmapped()
