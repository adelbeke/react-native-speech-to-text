// src/index.tsx
import { Platform } from 'react-native';
import NativeSpeechToText, { type Spec } from './ReactNativeSpeechToText';

const LINKING_ERROR =
  `The package '@dkable/react-native-speech-to-text' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({
    ios: "- Run 'pod install' in the ios/ directory\n",
    default: '',
  }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

const SpeechToTextModule = NativeSpeechToText
  ? NativeSpeechToText
  : new Proxy({} as Spec, {
      get() {
        throw new Error(LINKING_ERROR);
      },
    });

export interface SpeechResult {
  transcript: string;
  confidence: number;
}

export interface SpeechToTextOptions {
  language: string;
}

/**
 * Start speech recognition
 * @param options - Configuration options
 * @param options.language - Language code
 */
export async function start(options: SpeechToTextOptions): Promise<void> {
  const language = options.language;
  return SpeechToTextModule.start(language);
}

/**
 * Stop speech recognition and get the result
 * @returns The transcribed text and confidence score
 */
export async function stop(): Promise<SpeechResult> {
  return SpeechToTextModule.stop();
}

/**
 * Request microphone and speech recognition permissions
 * @returns true if permissions granted, false otherwise
 */
export async function requestPermissions(): Promise<boolean> {
  return SpeechToTextModule.requestPermissions();
}

/**
 * Check if speech recognition is available
 * @returns true if available, false otherwise
 */
export async function isAvailable(): Promise<boolean> {
  return SpeechToTextModule.isAvailable();
}
