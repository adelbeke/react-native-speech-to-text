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
  private var savedAudioSession: (category: AVAudioSession.Category, mode: AVAudioSession.Mode)?

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
      savedAudioSession = (audioSession.category, audioSession.mode)
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

      guard recordingFormat.sampleRate > 0 && recordingFormat.channelCount > 0 else {
        reject("AUDIO_ERROR", "Invalid audio input format", nil)
        return
      }

      inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
        recognitionRequest.append(buffer)
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return }
        var sum: Float = 0
        for i in 0..<frameLength { sum += channelData[i] * channelData[i] }
        let rms = (sum / Float(frameLength)).squareRoot()
        let level = Double(min(1.0, max(0.0, 1.0 + log10(max(Double(rms), 1e-7)) / 4.0)))
        self?.sendEvent(name: "audioMeterUpdate", body: ["level": level])
      }

      audioEngine.prepare()
      try audioEngine.start()

      recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
        guard let self = self else { return }

        if let error = error {
          if !self.isManuallyStopped {
            let errorCode = self.mapErrorCode(from: error)
            let errorMessage = self.mapErrorMessage(from: error)
            self.sendEvent(name: "onSpeechError", body: [
              "code": errorCode,
              "message": errorMessage
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

          if isFinal && !self.isManuallyStopped {
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
    if let saved = savedAudioSession {
      try? AVAudioSession.sharedInstance().setCategory(saved.category, mode: saved.mode)
    }
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
  }

  private func getConfidence(from result: SFSpeechRecognitionResult) -> Double {
    guard let segment = result.bestTranscription.segments.last else {
      return 0.0
    }
    return Double(segment.confidence)
  }

  private func mapErrorCode(from error: Error) -> String {
    let nsError = error as NSError

    if nsError.domain == "kLSRErrorDomain" {
      switch nsError.code {
      case 1: return "PERMISSION_DENIED"
      case 2: return "NOT_AVAILABLE"
      case 4: return "NETWORK_ERROR"
      case 7: return "RECOGNIZER_BUSY"
      default: return "UNKNOWN_ERROR"
      }
    }

    if nsError.domain == NSOSStatusErrorDomain || nsError.domain == AVFoundationErrorDomain {
      return "AUDIO_ERROR"
    }

    return "UNKNOWN_ERROR"
  }

  private func mapErrorMessage(from error: Error) -> String {
    let nsError = error as NSError

    if nsError.domain == "kLSRErrorDomain" {
      switch nsError.code {
      case 1: return "Insufficient permissions"
      case 2: return "Speech recognizer not available"
      case 4: return "Network error"
      case 7: return "Recognizer busy"
      default: return "Unknown error"
      }
    }

    if nsError.domain == NSOSStatusErrorDomain || nsError.domain == AVFoundationErrorDomain {
      return "Audio recording error"
    }

    return "Unknown error"
  }

  private func sendEvent(name: String, body: [String: Any]) {
    eventEmitter?.sendEvent(withName: name, body: body)
  }
}
