package com.dbkable.reactnativespeechtotext

import com.facebook.react.BaseReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.module.model.ReactModuleInfo
import com.facebook.react.module.model.ReactModuleInfoProvider
import java.util.HashMap

class ReactNativeSpeechToTextPackage : BaseReactPackage() {
  override fun getModule(name: String, reactContext: ReactApplicationContext): NativeModule? {
    return if (name == ReactNativeSpeechToTextModule.NAME) {
      ReactNativeSpeechToTextModule(reactContext)
    } else {
      null
    }
  }

  override fun getReactModuleInfoProvider(): ReactModuleInfoProvider {
    return ReactModuleInfoProvider {
      val moduleInfos: MutableMap<String, ReactModuleInfo> = HashMap()
      moduleInfos[ReactNativeSpeechToTextModule.NAME] = ReactModuleInfo(
        ReactNativeSpeechToTextModule.NAME,
        ReactNativeSpeechToTextModule.NAME,
        false,  // canOverrideExistingModule
        false,  // needsEagerInit
        false,  // isCxxModule
        true // isTurboModule
      )
      moduleInfos
    }
  }
}
