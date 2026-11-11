import Foundation
import Speech
import AVFoundation
import React

private let finalResultTimeout: TimeInterval = 1.0

@objc(SpeechToTextImpl)
public class SpeechToTextImpl: NSObject {

  private var speechRecognizer: SFSpeechRecognizer?
  private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
  private var recognitionTask: SFSpeechRecognitionTask?
  private var audioEngine = AVAudioEngine()
  private weak var eventEmitter: RCTEventEmitter?
  private var transcriptAccumulator = TranscriptAccumulator()
  private var lastTranscript: String { transcriptAccumulator.transcript }
  private var lastConfidence: Double = 0.0
  private var isManuallyStopped: Bool = false
  private var isFinishing: Bool = false
  private var finishTimeout: DispatchWorkItem?
  private var pendingStopResolvers: [RCTPromiseResolveBlock] = []
  private var savedAudioSession: (category: AVAudioSession.Category, mode: AVAudioSession.Mode, options: AVAudioSession.CategoryOptions)?

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

  @objc public func isOnDeviceAvailable(
  language: String,
  resolve: @escaping RCTPromiseResolveBlock,
  reject: @escaping RCTPromiseRejectBlock
  ) {
    let recognizer = SFSpeechRecognizer(locale: Locale(identifier: language))
    resolve(recognizer?.supportsOnDeviceRecognition ?? false)
  }

  @objc public func start(
  language: String,
  onDevice: Bool,
  resolve: @escaping RCTPromiseResolveBlock,
  reject: @escaping RCTPromiseRejectBlock
  ) {
    let isAlreadyListening = DispatchQueue.main.sync { () -> Bool in
      if self.isFinishing { self.completeStop() }
      return self.recognitionTask != nil
    }
    guard !isAlreadyListening else {
      reject("RECOGNIZER_BUSY", "Recognition already in progress", nil)
      return
    }

    transcriptAccumulator = TranscriptAccumulator()
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
      savedAudioSession = (audioSession.category, audioSession.mode, audioSession.categoryOptions)
      try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
      try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

      let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
      self.recognitionRequest = recognitionRequest

      recognitionRequest.shouldReportPartialResults = true
      if onDevice && speechRecognizer.supportsOnDeviceRecognition {
        recognitionRequest.requiresOnDeviceRecognition = true
      }

      let inputNode = audioEngine.inputNode
      // installTap raises an uncatchable ObjC exception when the tap format differs from the hardware input format.
      let recordingFormat = inputNode.inputFormat(forBus: 0)

      guard recordingFormat.sampleRate > 0 && recordingFormat.channelCount > 0 else {
        stopRecognition()
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
        guard let self = self, recognitionRequest === self.recognitionRequest else { return }

        if let error = error {
          if self.isFinishing {
            self.completeStop()
          } else if !self.isManuallyStopped {
            self.stopRecognition()
            let errorCode = self.mapErrorCode(from: error)
            let errorMessage = self.mapErrorMessage(from: error)
            self.sendEvent(name: "onSpeechError", body: [
              "code": errorCode,
              "message": errorMessage
            ])
            self.sendEvent(name: "onSpeechEnd", body: [:])
          }
          return
        }

        if let result = result {
          // The recognizer attaches metadata to the last result of each utterance.
          let transcript = self.transcriptAccumulator.add(
            result.bestTranscription.formattedString,
            utteranceEnded: result.speechRecognitionMetadata != nil
          )
          let isFinal = result.isFinal
          let confidence = self.getConfidence(from: result)

          self.lastConfidence = confidence

          if isFinal && self.isFinishing {
            self.completeStop()
            return
          }

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
      stopRecognition()
      reject("START_FAILED", "Failed to start recognition: \(error.localizedDescription)", error)
    }
  }

  @objc public func stop(
  resolve: @escaping RCTPromiseResolveBlock,
  reject: @escaping RCTPromiseRejectBlock
  ) {
    DispatchQueue.main.async {
      guard self.isFinishing || self.recognitionTask != nil else {
        resolve(nil)
        return
      }

      self.pendingStopResolvers.append(resolve)
      guard !self.isFinishing else { return }

      self.isManuallyStopped = true
      self.isFinishing = true
      self.audioEngine.stop()
      self.audioEngine.inputNode.removeTap(onBus: 0)
      self.recognitionRequest?.endAudio()

      let timeout = DispatchWorkItem { [weak self] in self?.completeStop() }
      self.finishTimeout = timeout
      DispatchQueue.main.asyncAfter(deadline: .now() + finalResultTimeout, execute: timeout)
    }
  }

  private func completeStop() {
    isFinishing = false
    finishTimeout?.cancel()
    finishTimeout = nil

    if !lastTranscript.isEmpty {
      sendEvent(name: "onSpeechResult", body: [
        "transcript": lastTranscript,
        "isFinal": true,
        "confidence": lastConfidence
      ])
    }

    stopRecognition()
    sendEvent(name: "onSpeechEnd", body: [:])

    let resolvers = pendingStopResolvers
    pendingStopResolvers = []
    resolvers.forEach { $0(nil) }
  }

  private func stopRecognition() {
    audioEngine.stop()
    audioEngine.inputNode.removeTap(onBus: 0)
    recognitionRequest?.endAudio()
    recognitionTask?.cancel()
    recognitionRequest = nil
    recognitionTask = nil
    guard let saved = savedAudioSession else { return }
    savedAudioSession = nil
    let audioSession = AVAudioSession.sharedInstance()
    try? audioSession.setCategory(saved.category, mode: saved.mode, options: saved.options)
    try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
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
