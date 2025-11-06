const { withInfoPlist, withAndroidManifest } = require('@expo/config-plugins');

const withSpeechToText = (config, props = {}) => {
  const {
    microphonePermission = 'Allow $(PRODUCT_NAME) to access your microphone to record audio for speech recognition',
    speechRecognitionPermission = 'Allow $(PRODUCT_NAME) to use speech recognition to convert your voice to text',
  } = props;

  config = withInfoPlist(config, (config) => {
    config.modResults.NSSpeechRecognitionUsageDescription =
      speechRecognitionPermission;
    config.modResults.NSMicrophoneUsageDescription = microphonePermission;
    return config;
  });

  config = withAndroidManifest(config, (config) => {
    const androidManifest = config.modResults.manifest;

    if (!androidManifest['uses-permission']) {
      androidManifest['uses-permission'] = [];
    }

    const hasRecordAudio = androidManifest['uses-permission'].some(
      (perm) => perm.$['android:name'] === 'android.permission.RECORD_AUDIO'
    );

    if (!hasRecordAudio) {
      androidManifest['uses-permission'].push({
        $: { 'android:name': 'android.permission.RECORD_AUDIO' },
      });
    }

    return config;
  });

  return config;
};

module.exports = withSpeechToText;
