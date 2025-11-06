package com.dbkable.reactnativespeechtotext

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import androidx.core.content.ContextCompat
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.WritableMap
import com.facebook.react.modules.core.DeviceEventManagerModule

class ReactNativeSpeechToTextModule(reactContext: ReactApplicationContext) :
  ReactContextBaseJavaModule(reactContext) {

  private var speechRecognizer: SpeechRecognizer? = null
  private var lastTranscript: String = ""
  private var lastConfidence: Double = 0.0
  private var isManuallyStopped: Boolean = false

  override fun getName(): String {
    return NAME
  }

  private fun sendEvent(eventName: String, params: WritableMap?) {
    reactApplicationContext
      .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
      .emit(eventName, params)
  }

  @ReactMethod
  fun start(language: String, promise: Promise) {
    val context = reactApplicationContext

    lastTranscript = ""
    lastConfidence = 0.0
    isManuallyStopped = false

    if (ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO)
      != PackageManager.PERMISSION_GRANTED) {
      promise.reject("PERMISSION_DENIED", "Microphone permission not granted")
      return
    }

    if (!SpeechRecognizer.isRecognitionAvailable(context)) {
      promise.reject("NOT_AVAILABLE", "Speech recognition not available")
      return
    }

    android.os.Handler(android.os.Looper.getMainLooper()).post {
      try {
        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(context)

        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
          putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
          putExtra(RecognizerIntent.EXTRA_LANGUAGE, language)
          putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
          putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
          putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, 2000L)
          putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS, 2000L)
          putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_MINIMUM_LENGTH_MILLIS, 10000L)
        }

        speechRecognizer?.setRecognitionListener(object : RecognitionListener {
          override fun onReadyForSpeech(params: Bundle?) {}
          override fun onBeginningOfSpeech() {}
          override fun onRmsChanged(rmsdB: Float) {}
          override fun onBufferReceived(buffer: ByteArray?) {}

          override fun onEndOfSpeech() {
            if (!isManuallyStopped) {
              val event = Arguments.createMap()
              sendEvent("onSpeechEnd", event)
            }
          }

          override fun onError(error: Int) {
            if (!isManuallyStopped) {
              if (error == SpeechRecognizer.ERROR_NO_MATCH ||
                error == SpeechRecognizer.ERROR_SPEECH_TIMEOUT) {
                return
              }

              val errorCode = when (error) {
                SpeechRecognizer.ERROR_AUDIO -> "AUDIO_ERROR"
                SpeechRecognizer.ERROR_CLIENT -> "CLIENT_ERROR"
                SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "PERMISSION_DENIED"
                SpeechRecognizer.ERROR_NETWORK -> "NETWORK_ERROR"
                SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "NETWORK_TIMEOUT"
                SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "RECOGNIZER_BUSY"
                SpeechRecognizer.ERROR_SERVER -> "SERVER_ERROR"
                else -> "UNKNOWN_ERROR"
              }

              val errorMessage = when (error) {
                SpeechRecognizer.ERROR_AUDIO -> "Audio recording error"
                SpeechRecognizer.ERROR_CLIENT -> "Client error"
                SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "Insufficient permissions"
                SpeechRecognizer.ERROR_NETWORK -> "Network error"
                SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "Network timeout"
                SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "Recognizer busy"
                SpeechRecognizer.ERROR_SERVER -> "Server error"
                else -> "Unknown error"
              }

              val event = Arguments.createMap()
              event.putString("code", errorCode)
              event.putString("message", errorMessage)
              sendEvent("onSpeechError", event)
            }
          }

          override fun onResults(results: Bundle?) {
            results?.let {
              val matches = it.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
              val scores = it.getFloatArray(SpeechRecognizer.CONFIDENCE_SCORES)

              if (matches != null && matches.isNotEmpty()) {
                lastTranscript = matches[0]
                lastConfidence = scores?.get(0)?.toDouble() ?: 0.0

                val event = Arguments.createMap()
                event.putString("transcript", lastTranscript)
                event.putBoolean("isFinal", true)
                event.putDouble("confidence", lastConfidence)
                sendEvent("onSpeechResult", event)
              }
            }
          }

          override fun onPartialResults(partialResults: Bundle?) {
            partialResults?.let {
              val matches = it.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
              val scores = it.getFloatArray(SpeechRecognizer.CONFIDENCE_SCORES)

              if (matches != null && matches.isNotEmpty()) {
                lastTranscript = matches[0]
                lastConfidence = scores?.get(0)?.toDouble() ?: 0.0

                val event = Arguments.createMap()
                event.putString("transcript", lastTranscript)
                event.putBoolean("isFinal", false)
                event.putDouble("confidence", lastConfidence)
                sendEvent("onSpeechResult", event)
              }
            }
          }

          override fun onEvent(eventType: Int, params: Bundle?) {}
        })

        speechRecognizer?.startListening(intent)
        promise.resolve(null)

      } catch (e: Exception) {
        promise.reject("START_FAILED", "Failed to start recognition: ${e.message}", e)
      }
    }
  }

  @ReactMethod
  fun stop(promise: Promise) {
    isManuallyStopped = true

    android.os.Handler(android.os.Looper.getMainLooper()).post {
      try {
        if (lastTranscript.isNotEmpty()) {
          val event = Arguments.createMap()
          event.putString("transcript", lastTranscript)
          event.putBoolean("isFinal", true)
          event.putDouble("confidence", lastConfidence)
          sendEvent("onSpeechResult", event)
        }

        speechRecognizer?.stopListening()
        speechRecognizer?.destroy()
        speechRecognizer = null

        val endEvent = Arguments.createMap()
        sendEvent("onSpeechEnd", endEvent)

        promise.resolve(null)
      } catch (e: Exception) {
        promise.reject("STOP_FAILED", "Failed to stop recognition: ${e.message}", e)
      }
    }
  }

  @ReactMethod
  fun requestPermissions(promise: Promise) {
    val context = reactApplicationContext
    val hasPermission = ContextCompat.checkSelfPermission(
      context,
      Manifest.permission.RECORD_AUDIO
    ) == PackageManager.PERMISSION_GRANTED

    promise.resolve(hasPermission)
  }

  @ReactMethod
  fun isAvailable(promise: Promise) {
    val context = reactApplicationContext
    val available = SpeechRecognizer.isRecognitionAvailable(context)
    promise.resolve(available)
  }

  @ReactMethod
  fun addListener(eventName: String) {}

  @ReactMethod
  fun removeListeners(count: Int) {}

  override fun invalidate() {
    super.invalidate()
    android.os.Handler(android.os.Looper.getMainLooper()).post {
      speechRecognizer?.destroy()
      speechRecognizer = null
    }
  }

  companion object {
    const val NAME = "ReactNativeSpeechToText"
  }
}
