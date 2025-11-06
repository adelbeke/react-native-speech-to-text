#import "ReactNativeSpeechToText.h"

@interface SpeechToTextImpl : NSObject
- (instancetype)initWithEventEmitter:(RCTEventEmitter *)emitter;
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

@implementation ReactNativeSpeechToText {
  SpeechToTextImpl *_impl;
  BOOL _hasListeners;
}

RCT_EXPORT_MODULE(ReactNativeSpeechToText)

+ (BOOL)requiresMainQueueSetup {
  return NO;
}

- (instancetype)init {
  if (self = [super init]) {
    _impl = [[SpeechToTextImpl alloc] initWithEventEmitter:self];
    _hasListeners = NO;
  }
  return self;
}

- (NSArray<NSString *> *)supportedEvents {
  return @[@"onSpeechResult", @"onSpeechError", @"onSpeechEnd"];
}

- (void)startObserving {
  _hasListeners = YES;
}

- (void)stopObserving {
  _hasListeners = NO;
}

RCT_EXPORT_METHOD(start:(NSString *)language
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
  [_impl startWithLanguage:language resolve:resolve reject:reject];
}

RCT_EXPORT_METHOD(stop:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
  [_impl stopWithResolve:resolve reject:reject];
}

RCT_EXPORT_METHOD(requestPermissions:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
  [_impl requestPermissionsWithResolve:resolve reject:reject];
}

RCT_EXPORT_METHOD(isAvailable:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
  [_impl isAvailableWithResolve:resolve reject:reject];
}

RCT_EXPORT_METHOD(addListener:(NSString *)eventName) {
  [super addListener:eventName];
}

RCT_EXPORT_METHOD(removeListeners:(double)count) {
  [super removeListeners:count];
}

@end
