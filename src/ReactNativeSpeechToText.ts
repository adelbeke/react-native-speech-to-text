import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

export interface SpeechResult {
  transcript: string;
  confidence: number;
  isFinal: boolean;
}

export interface Spec extends TurboModule {
  start(language: string): Promise<void>;
  stop(): Promise<void>;
  requestPermissions(): Promise<boolean>;
  isAvailable(): Promise<boolean>;
  addListener(eventName: string): void;
  removeListeners(count: number): void;
}

export default TurboModuleRegistry.getEnforcing<Spec>(
  'ReactNativeSpeechToText'
);
