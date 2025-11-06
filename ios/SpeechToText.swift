import Foundation
import Speech
import AVFoundation
import React

@objc(SpeechToTextImpl)
public class SpeechToTextImpl: NSObject {

  private var speechRecognizer: SFSpeechRecognizer?
  private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
  private var recognitionTask: SFSpeechRecognitionTask?
  private var audioEngine = AVAudioEngine()
  private weak var eventEmitter: RCTEventEmitter?
  private var lastTranscript: String = ""
  private var lastConfidence: Double = 0.0
  private var isManuallyStopped: Bool = false

  @objc public init(eventEmitter: RCTEventEmitter) {
    self.eventEmitter = eventEmitter
    super.init()
  }

  @objc public func requestPermissions(
  resolve: @escaping RCTPromiseResolveBlock,
  reject: @escaping RCTPromiseRejectBlock
  ) {
    SFSpeechRecognizer.requestAuthorization { authStatus in
      DispatchQueue.main.async {
        switch authStatus {
        case .authorized:
          AVAudioSession.sharedInstance().requestRecordPermission { granted in
            resolve(granted)
          }
        case .denied, .restricted, .notDetermined:
          resolve(false)
        @unknown default:
          resolve(false)
        }
      }
    }
  }

  @objc public func isAvailable(
  resolve: @escaping RCTPromiseResolveBlock,
  reject: @escaping RCTPromiseRejectBlock
  ) {
    let authStatus = SFSpeechRecognizer.authorizationStatus()
    let recognizerAvailable = SFSpeechRecognizer(locale: Locale(identifier: "en-US")) != nil
    let available = (authStatus == .authorized || authStatus == .notDetermined) && recognizerAvailable
    resolve(available)
  }

  @objc public func start(
  language: String,
  resolve: @escaping RCTPromiseResolveBlock,
  reject: @escaping RCTPromiseRejectBlock
  ) {
    lastTranscript = ""
    lastConfidence = 0.0
    isManuallyStopped = false

    guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
      reject("PERMISSION_DENIED", "Speech recognition not authorized", nil)
      return
    }

    let locale = Locale(identifier: language)
    speechRecognizer = SFSpeechRecognizer(locale: locale)

    guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
      reject("NOT_AVAILABLE", "Speech recognizer not available", nil)
      return
    }

    do {
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
      try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

      recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
      guard let recognitionRequest = recognitionRequest else {
        reject("REQUEST_FAILED", "Unable to create recognition request", nil)
        return
      }

      recognitionRequest.shouldReportPartialResults = true

      let inputNode = audioEngine.inputNode
      let recordingFormat = inputNode.outputFormat(forBus: 0)

      inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
        recognitionRequest.append(buffer)
      }

      audioEngine.prepare()
      try audioEngine.start()

      recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
        guard let self = self else { return }

        if let error = error {
          if !self.isManuallyStopped {
            self.sendEvent(name: "onSpeechError", body: [
              "error": error.localizedDescription
            ])
          }
          return
        }

        if let result = result {
          let transcript = result.bestTranscription.formattedString
          let isFinal = result.isFinal
          let confidence = self.getConfidence(from: result)

          self.lastTranscript = transcript
          self.lastConfidence = confidence

          self.sendEvent(name: "onSpeechResult", body: [
            "transcript": transcript,
            "isFinal": isFinal,
            "confidence": confidence
          ])

          if isFinal {
            self.stopRecognition()
            self.sendEvent(name: "onSpeechEnd", body: [:])
          }
        }
      }

      resolve(nil)

    } catch {
      reject("START_FAILED", "Failed to start recognition: \(error.localizedDescription)", error)
    }
  }

  @objc public func stop(
  resolve: @escaping RCTPromiseResolveBlock,
  reject: @escaping RCTPromiseRejectBlock
  ) {
    isManuallyStopped = true

    if !lastTranscript.isEmpty {
      sendEvent(name: "onSpeechResult", body: [
        "transcript": lastTranscript,
        "isFinal": true,
        "confidence": lastConfidence
      ])
    }

    stopRecognition()
    sendEvent(name: "onSpeechEnd", body: [:])
    resolve(nil)
  }

  private func stopRecognition() {
    audioEngine.stop()
    audioEngine.inputNode.removeTap(onBus: 0)
    recognitionRequest?.endAudio()
    recognitionTask?.cancel()
    recognitionRequest = nil
    recognitionTask = nil
  }

  private func getConfidence(from result: SFSpeechRecognitionResult) -> Double {
    guard let segment = result.bestTranscription.segments.last else {
      return 0.0
    }
    return Double(segment.confidence)
  }

  private func sendEvent(name: String, body: [String: Any]) {
    eventEmitter?.sendEvent(withName: name, body: body)
  }
}
