import { TurboModuleRegistry, type TurboModule } from 'react-native';

export interface SpeechResult {
  transcript: string;
  confidence: number;
}

export interface Spec extends TurboModule {
  start(language: string): Promise<void>;
  stop(): Promise<SpeechResult>;
  requestPermissions(): Promise<boolean>;
  isAvailable(): Promise<boolean>;
}

export default TurboModuleRegistry.getEnforcing<Spec>(
  'ReactNativeSpeechToText'
);
