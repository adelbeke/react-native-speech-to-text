import { type ConfigPlugin, withInfoPlist } from '@expo/config-plugins';

export interface SpeechToTextPluginProps {
  microphonePermission?: string;
  speechRecognitionPermission?: string;
}

export const withIosConfiguration: ConfigPlugin<SpeechToTextPluginProps> = (
  config,
  props = {}
) => {
  const {
    microphonePermission = 'Allow $(PRODUCT_NAME) to access your microphone to record audio for speech recognition',
    speechRecognitionPermission = 'Allow $(PRODUCT_NAME) to use speech recognition to convert your voice to text',
  } = props;

  return withInfoPlist(config, (config) => {
    config.modResults.NSSpeechRecognitionUsageDescription =
      speechRecognitionPermission;
    config.modResults.NSMicrophoneUsageDescription = microphonePermission;
    return config;
  });
};
