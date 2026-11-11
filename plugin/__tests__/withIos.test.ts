import type { InfoPlist } from 'expo/config-plugins';
import { setSpeechUsageDescriptions } from '../src/withIos';

describe('setSpeechUsageDescriptions', () => {
  it('keeps existing Info.plist strings when no prop is passed', () => {
    // GIVEN
    const infoPlist: InfoPlist = {
      NSMicrophoneUsageDescription: 'Existing mic',
      NSSpeechRecognitionUsageDescription: 'Existing speech',
    };

    // WHEN
    const actual = setSpeechUsageDescriptions(infoPlist, {});

    // THEN
    expect(actual.NSMicrophoneUsageDescription).toBe('Existing mic');
    expect(actual.NSSpeechRecognitionUsageDescription).toBe('Existing speech');
  });

  it('overrides existing Info.plist strings with props', () => {
    // GIVEN
    const infoPlist: InfoPlist = {
      NSMicrophoneUsageDescription: 'Existing mic',
      NSSpeechRecognitionUsageDescription: 'Existing speech',
    };

    // WHEN
    const actual = setSpeechUsageDescriptions(infoPlist, {
      microphonePermission: 'Prop mic',
      speechRecognitionPermission: 'Prop speech',
    });

    // THEN
    expect(actual.NSMicrophoneUsageDescription).toBe('Prop mic');
    expect(actual.NSSpeechRecognitionUsageDescription).toBe('Prop speech');
  });

  it('falls back to default strings when neither prop nor existing value is set', () => {
    // GIVEN
    const infoPlist: InfoPlist = {};

    // WHEN
    const actual = setSpeechUsageDescriptions(infoPlist, {});

    // THEN
    expect(actual.NSMicrophoneUsageDescription).toMatch(/microphone/);
    expect(actual.NSSpeechRecognitionUsageDescription).toMatch(
      /speech recognition/
    );
  });
});
