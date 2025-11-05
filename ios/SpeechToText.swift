// ios/SpeechToText.swift
import Foundation
import Speech
import AVFoundation

@objc(SpeechToTextImpl)
public class SpeechToTextImpl: NSObject {

  @objc public static let shared = SpeechToTextImpl()

  private var speechRecognizer: SFSpeechRecognizer?
  private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
  private var recognitionTask: SFSpeechRecognitionTask?
  private var audioEngine = AVAudioEngine()

  private var lastResult: SFSpeechRecognitionResult?

  private override init() {
    super.init()
  }

  // MARK: - Request Permissions

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

  // MARK: - Check Availability

  @objc public func isAvailable(
  resolve: @escaping RCTPromiseResolveBlock,
  reject: @escaping RCTPromiseRejectBlock
  ) {
    let available = SFSpeechRecognizer.authorizationStatus() == .authorized
    resolve(available)
  }

  // MARK: - Start Recognition

  @objc public func start(
  language: String,
  resolve: @escaping RCTPromiseResolveBlock,
  reject: @escaping RCTPromiseRejectBlock
  ) {
    // Reset previous state
    lastResult = nil

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
          print("Recognition error: \(error.localizedDescription)")
          return
        }

        if let result = result {
          self.lastResult = result
        }
      }

      resolve(nil)

    } catch {
      reject("START_FAILED", "Failed to start recognition: \(error.localizedDescription)", error)
    }
  }

  // MARK: - Stop Recognition

  @objc public func stop(
  resolve: @escaping RCTPromiseResolveBlock,
  reject: @escaping RCTPromiseRejectBlock
  ) {
    audioEngine.stop()
    audioEngine.inputNode.removeTap(onBus: 0)
    recognitionRequest?.endAudio()

    if let result = lastResult {
      let transcript = result.bestTranscription.formattedString
      let confidence = getConfidence(from: result)

      resolve([
        "transcript": transcript,
        "confidence": confidence
      ])
    } else {
      resolve([
        "transcript": "",
        "confidence": 0.0
      ])
    }

    // Cleanup
    recognitionTask?.cancel()
    recognitionRequest = nil
    recognitionTask = nil
    lastResult = nil
  }

  // MARK: - Private Helpers

  private func getConfidence(from result: SFSpeechRecognitionResult) -> Double {
    guard let segment = result.bestTranscription.segments.last else {
      return 0.0
    }
    return Double(segment.confidence)
  }
}
