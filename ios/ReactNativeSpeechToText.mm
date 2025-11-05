// ios/ReactNativeSpeechToText.mm
#import "ReactNativeSpeechToText.h"
#import "react_native_speech_to_text-Swift.h"

@implementation ReactNativeSpeechToText

RCT_EXPORT_MODULE(ReactNativeSpeechToText)

+ (BOOL)requiresMainQueueSetup {
  return NO;
}

RCT_EXPORT_METHOD(start:(NSString *)language
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
  [[SpeechToTextImpl shared] startWithLanguage:language
                                       resolve:resolve
                                        reject:reject];
}

RCT_EXPORT_METHOD(stop:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
  [[SpeechToTextImpl shared] stopWithResolve:resolve reject:reject];
}

RCT_EXPORT_METHOD(requestPermissions:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
  [[SpeechToTextImpl shared] requestPermissionsWithResolve:resolve reject:reject];
}

RCT_EXPORT_METHOD(isAvailable:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
  [[SpeechToTextImpl shared] isAvailableWithResolve:resolve reject:reject];
}

@end
