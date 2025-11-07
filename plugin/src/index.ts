import type { ConfigPlugin } from '@expo/config-plugins';
import { withAndroidConfiguration } from './withAndroid';
import { withIosConfiguration } from './withIos';

export interface SpeechToTextPluginProps {
  microphonePermission?: string;
  speechRecognitionPermission?: string;
}

const withSpeechToText: ConfigPlugin<SpeechToTextPluginProps> = (
  config,
  props = {}
) => {
  config = withAndroidConfiguration(config, props);
  config = withIosConfiguration(config, props);
  return config;
};

export default withSpeechToText;
