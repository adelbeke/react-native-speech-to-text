import {
  type ConfigPlugin,
  type InfoPlist,
  withInfoPlist,
} from 'expo/config-plugins';

export interface SpeechToTextPluginProps {
  microphonePermission?: string;
  speechRecognitionPermission?: string;
}

const DEFAULT_MICROPHONE_PERMISSION =
  'Allow $(PRODUCT_NAME) to access your microphone to record audio for speech recognition';
const DEFAULT_SPEECH_RECOGNITION_PERMISSION =
  'Allow $(PRODUCT_NAME) to use speech recognition to convert your voice to text';

export const setSpeechUsageDescriptions = (
  infoPlist: InfoPlist,
  props: SpeechToTextPluginProps
): InfoPlist => ({
  ...infoPlist,
  NSMicrophoneUsageDescription:
    props.microphonePermission ??
    infoPlist.NSMicrophoneUsageDescription ??
    DEFAULT_MICROPHONE_PERMISSION,
  NSSpeechRecognitionUsageDescription:
    props.speechRecognitionPermission ??
    infoPlist.NSSpeechRecognitionUsageDescription ??
    DEFAULT_SPEECH_RECOGNITION_PERMISSION,
});

export const withIosConfiguration: ConfigPlugin<SpeechToTextPluginProps> = (
  config,
  props = {}
) =>
  withInfoPlist(config, (config) => {
    config.modResults = setSpeechUsageDescriptions(config.modResults, props);
    return config;
  });
