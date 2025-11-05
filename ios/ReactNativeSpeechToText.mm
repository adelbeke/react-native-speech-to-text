// ios/ReactNativeSpeechToText.mm
#import "ReactNativeSpeechToText.h"

@interface SpeechToTextImpl : NSObject
+ (instancetype)shared;
- (void)startWithLanguage:(NSString *)language
                  resolve:(RCTPromiseResolveBlock)resolve
                   reject:(RCTPromiseRejectBlock)reject;
- (void)stopWithResolve:(RCTPromiseResolveBlock)resolve
                 reject:(RCTPromiseRejectBlock)reject;
- (void)requestPermissionsWithResolve:(RCTPromiseResolveBlock)resolve
                               reject:(RCTPromiseRejectBlock)reject;
- (void)isAvailableWithResolve:(RCTPromiseResolveBlock)resolve
                        reject:(RCTPromiseRejectBlock)reject;
@end

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
