import { type ConfigPlugin, withAndroidManifest } from '@expo/config-plugins';

export interface SpeechToTextPluginProps {
  microphonePermission?: string;
}

export const withAndroidConfiguration: ConfigPlugin<SpeechToTextPluginProps> = (
  config
) => {
  return withAndroidManifest(config, (config) => {
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
};
