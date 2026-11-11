package com.dbkable.reactnativespeechtotext

internal class FinalResultWait<T> {
  private val pendingStops = mutableListOf<T>()

  var isWaiting: Boolean = false
    private set

  fun begin(stop: T): Boolean {
    pendingStops.add(stop)
    if (isWaiting) return false
    isWaiting = true
    return true
  }

  fun finish(): List<T>? {
    if (!isWaiting) return null
    isWaiting = false
    val stops = pendingStops.toList()
    pendingStops.clear()
    return stops
  }
}
