package com.dbkable.reactnativespeechtotext

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class FinalResultWaitTest {

  @Test
  fun begin_startsWaiting_onFirstStop() {
    // GIVEN
    val wait = FinalResultWait<String>()

    // WHEN
    val actual = wait.begin("first")

    // THEN
    assertTrue(actual)
    assertTrue(wait.isWaiting)
  }

  @Test
  fun begin_doesNotStartAgain_whenStopIsCalledTwiceWhileWaiting() {
    // GIVEN
    val wait = FinalResultWait<String>()
    wait.begin("first")

    // WHEN
    val actual = wait.begin("second")

    // THEN
    assertFalse(actual)
  }

  @Test
  fun finish_returnsEveryPendingStop_inCallOrder() {
    // GIVEN
    val wait = FinalResultWait<String>()
    wait.begin("first")
    wait.begin("second")

    // WHEN
    val actual = wait.finish()

    // THEN
    val expected = listOf("first", "second")
    assertEquals(expected, actual)
    assertFalse(wait.isWaiting)
  }

  @Test
  fun finish_returnsNull_whenFinalResultAndTimeoutBothFire() {
    // GIVEN
    val wait = FinalResultWait<String>()
    wait.begin("first")
    wait.finish()

    // WHEN
    val actual = wait.finish()

    // THEN
    assertNull(actual)
  }

  @Test
  fun finish_returnsNull_whenNothingWasStopped() {
    // GIVEN
    val wait = FinalResultWait<String>()

    // WHEN
    val actual = wait.finish()

    // THEN
    assertNull(actual)
  }
}
