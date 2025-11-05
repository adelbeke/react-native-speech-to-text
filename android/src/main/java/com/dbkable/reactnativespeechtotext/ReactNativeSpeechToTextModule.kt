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
import com.facebook.react.bridge.WritableMap
import com.facebook.react.module.annotations.ReactModule

@ReactModule(name = ReactNativeSpeechToTextModule.NAME)
class ReactNativeSpeechToTextModule(reactContext: ReactApplicationContext) :
  NativeReactNativeSpeechToTextSpec(reactContext) {

  private var speechRecognizer: SpeechRecognizer? = null
  private var recognitionResults: ArrayList<String>? = null
  private var confidenceScores: FloatArray? = null

  override fun getName(): String {
    return NAME
  }

  override fun start(language: String, promise: Promise) {
    val reactContext = reactApplicationContext

    if (ContextCompat.checkSelfPermission(reactContext, Manifest.permission.RECORD_AUDIO)
      != PackageManager.PERMISSION_GRANTED) {
      promise.reject("PERMISSION_DENIED", "Microphone permission not granted")
      return
    }

    if (!SpeechRecognizer.isRecognitionAvailable(reactContext)) {
      promise.reject("NOT_AVAILABLE", "Speech recognition not available")
      return
    }

    try {
      speechRecognizer = SpeechRecognizer.createSpeechRecognizer(reactContext)

      val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
        putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
        putExtra(RecognizerIntent.EXTRA_LANGUAGE, language)
        putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
        putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
      }

      speechRecognizer?.setRecognitionListener(object : RecognitionListener {
        override fun onReadyForSpeech(params: Bundle?) {
        }

        override fun onBeginningOfSpeech() {
        }

        override fun onRmsChanged(rmsdB: Float) {
        }

        override fun onBufferReceived(buffer: ByteArray?) {
        }

        override fun onEndOfSpeech() {
        }

        override fun onError(error: Int) {
          val errorMessage = when (error) {
            SpeechRecognizer.ERROR_AUDIO -> "Audio recording error"
            SpeechRecognizer.ERROR_CLIENT -> "Client error"
            SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "Insufficient permissions"
            SpeechRecognizer.ERROR_NETWORK -> "Network error"
            SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "Network timeout"
            SpeechRecognizer.ERROR_NO_MATCH -> "No match found"
            SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "Recognizer busy"
            SpeechRecognizer.ERROR_SERVER -> "Server error"
            SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "Speech timeout"
            else -> "Unknown error"
          }
        }

        override fun onResults(results: Bundle?) {
          results?.let {
            recognitionResults = it.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
            confidenceScores = it.getFloatArray(SpeechRecognizer.CONFIDENCE_SCORES)
          }
        }

        override fun onPartialResults(partialResults: Bundle?) {
        }

        override fun onEvent(eventType: Int, params: Bundle?) {
        }
      })

      speechRecognizer?.startListening(intent)
      promise.resolve(null)

    } catch (e: Exception) {
      promise.reject("START_FAILED", "Failed to start recognition: ${e.message}", e)
    }
  }

  override fun stop(promise: Promise) {
    try {
      speechRecognizer?.stopListening()

      android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
        val result: WritableMap = Arguments.createMap()

        if (recognitionResults != null && recognitionResults!!.isNotEmpty()) {
          result.putString("transcript", recognitionResults!![0])

          val confidence = if (confidenceScores != null && confidenceScores!!.isNotEmpty()) {
            confidenceScores!![0].toDouble()
          } else {
            0.0
          }
          result.putDouble("confidence", confidence)
        } else {
          result.putString("transcript", "")
          result.putDouble("confidence", 0.0)
        }

        speechRecognizer?.destroy()
        speechRecognizer = null
        recognitionResults = null
        confidenceScores = null

        promise.resolve(result)
      }, 500)

    } catch (e: Exception) {
      promise.reject("STOP_FAILED", "Failed to stop recognition: ${e.message}", e)
    }
  }

  override fun requestPermissions(promise: Promise) {
    val reactContext = reactApplicationContext
    val hasPermission = ContextCompat.checkSelfPermission(
      reactContext,
      Manifest.permission.RECORD_AUDIO
    ) == PackageManager.PERMISSION_GRANTED

    if (hasPermission) {
      promise.resolve(true)
    } else {
      promise.resolve(false)
    }
  }

  override fun isAvailable(promise: Promise) {
    val reactContext = reactApplicationContext
    val available = SpeechRecognizer.isRecognitionAvailable(reactContext)
    promise.resolve(available)
  }

  override fun invalidate() {
    super.invalidate()
    speechRecognizer?.destroy()
    speechRecognizer = null
  }

  companion object {
    const val NAME = "ReactNativeSpeechToText"
  }
}
