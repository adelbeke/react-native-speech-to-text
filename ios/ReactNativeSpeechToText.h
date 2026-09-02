#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

#ifdef RCT_NEW_ARCH_ENABLED
#import <ReactNativeSpeechToTextSpec/ReactNativeSpeechToTextSpec.h>

@interface ReactNativeSpeechToText : RCTEventEmitter <NativeReactNativeSpeechToTextSpec>
#else
@interface ReactNativeSpeechToText : RCTEventEmitter <RCTBridgeModule>
#endif
@end
