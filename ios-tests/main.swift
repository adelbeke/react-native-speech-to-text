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

test_keepsEarlierUtterance_whenRecognizerRestartsAfterPause()
test_doesNotDuplicate_whenRecognizerKeepsCumulativeText()
test_replacesRevisedPartials_withinOneUtterance()
test_keepsEveryUtterance_acrossSeveralPauses()
test_keepsCommittedText_whenNewUtteranceIsEmpty()
