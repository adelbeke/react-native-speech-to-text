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

    android.util.Log.d(NAME, "🎤 Starting recognition with language: $language")

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
          override fun onReadyForSpeech(params: Bundle?) {
            android.util.Log.d(NAME, "✅ Ready for speech")
          }

          override fun onBeginningOfSpeech() {
            android.util.Log.d(NAME, "✅ Beginning of speech")
          }

          override fun onRmsChanged(rmsdB: Float) {}
          override fun onBufferReceived(buffer: ByteArray?) {}

          override fun onEndOfSpeech() {
            android.util.Log.d(NAME, "🏁 End of speech")
            if (!isManuallyStopped) {
              val event = Arguments.createMap()
              sendEvent("onSpeechEnd", event)
            }
          }

          override fun onError(error: Int) {
            android.util.Log.d(NAME, "❌ Error: $error")
            if (!isManuallyStopped) {
              if (error == SpeechRecognizer.ERROR_NO_MATCH ||
                error == SpeechRecognizer.ERROR_SPEECH_TIMEOUT) {
                android.util.Log.d(NAME, "Ignoring error: $error (normal stop)")
                return
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
              event.putString("error", errorMessage)
              sendEvent("onSpeechError", event)
            }
          }

          override fun onResults(results: Bundle?) {
            android.util.Log.d(NAME, "🎯 Final results received")
            results?.let {
              val matches = it.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
              android.util.Log.d(NAME, "Final matches: $matches")

              val scores = it.getFloatArray(SpeechRecognizer.CONFIDENCE_SCORES)

              if (matches != null && matches.isNotEmpty()) {
                lastTranscript = matches[0]
                lastConfidence = scores?.get(0)?.toDouble() ?: 0.0

                android.util.Log.d(NAME, "Sending final: $lastTranscript")

                val event = Arguments.createMap()
                event.putString("transcript", lastTranscript)
                event.putBoolean("isFinal", true)
                event.putDouble("confidence", lastConfidence)
                sendEvent("onSpeechResult", event)
              }
            }
          }

          override fun onPartialResults(partialResults: Bundle?) {
            android.util.Log.d(NAME, "📝 Partial results received")
            partialResults?.let {
              val matches = it.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
              android.util.Log.d(NAME, "Partial matches: $matches")

              val scores = it.getFloatArray(SpeechRecognizer.CONFIDENCE_SCORES)

              if (matches != null && matches.isNotEmpty()) {
                lastTranscript = matches[0]
                lastConfidence = scores?.get(0)?.toDouble() ?: 0.0

                android.util.Log.d(NAME, "Sending partial: $lastTranscript")

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
        android.util.Log.d(NAME, "🎙️ Started listening")
        promise.resolve(null)

      } catch (e: Exception) {
        android.util.Log.e(NAME, "❌ Start failed: ${e.message}")
        promise.reject("START_FAILED", "Failed to start recognition: ${e.message}", e)
      }
    }
  }

  @ReactMethod
  fun stop(promise: Promise) {
    android.util.Log.d(NAME, "⏹ Stopping recognition")
    isManuallyStopped = true

    android.os.Handler(android.os.Looper.getMainLooper()).post {
      try {
        if (lastTranscript.isNotEmpty()) {
          android.util.Log.d(NAME, "Sending final on stop: $lastTranscript")
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

        android.util.Log.d(NAME, "✅ Stopped successfully")
        promise.resolve(null)
      } catch (e: Exception) {
        android.util.Log.e(NAME, "❌ Stop failed: ${e.message}")
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
