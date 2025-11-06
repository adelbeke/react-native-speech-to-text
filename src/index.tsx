import {
  NativeEventEmitter,
  NativeModules,
  Platform,
  PermissionsAndroid,
  type EmitterSubscription,
} from 'react-native';
import NativeSpeechToText, { type Spec } from './ReactNativeSpeechToText';

const LINKING_ERROR =
  `The package '@dkable/react-native-speech-to-text' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({
    ios: "- Run 'pod install' in the ios/ directory\n",
    android: '- Rebuild the app after installing the package\n',
    default: '',
  }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

const SpeechToTextModule: Spec = NativeSpeechToText
  ? NativeSpeechToText
  : new Proxy({} as Spec, {
      get() {
        throw new Error(LINKING_ERROR);
      },
    });

interface SpeechToTextEvents {
  onSpeechResult: SpeechResult;
  onSpeechError: SpeechError;
  onSpeechEnd: void;
}

type TypedEventEmitter = {
  addListener<K extends keyof SpeechToTextEvents>(
    eventType: K,
    listener: (event: SpeechToTextEvents[K]) => void
  ): EmitterSubscription;
};

const eventEmitter = new NativeEventEmitter(
  NativeModules.ReactNativeSpeechToText
) as TypedEventEmitter;

export interface SpeechResult {
  transcript: string;
  confidence: number;
  isFinal: boolean;
}

export enum SpeechErrorCode {
  PERMISSION_DENIED = 'PERMISSION_DENIED',
  NOT_AVAILABLE = 'NOT_AVAILABLE',
  REQUEST_FAILED = 'REQUEST_FAILED',
  START_FAILED = 'START_FAILED',
  STOP_FAILED = 'STOP_FAILED',
  AUDIO_ERROR = 'AUDIO_ERROR',
  CLIENT_ERROR = 'CLIENT_ERROR',
  NETWORK_ERROR = 'NETWORK_ERROR',
  NETWORK_TIMEOUT = 'NETWORK_TIMEOUT',
  RECOGNIZER_BUSY = 'RECOGNIZER_BUSY',
  SERVER_ERROR = 'SERVER_ERROR',
  UNKNOWN_ERROR = 'UNKNOWN_ERROR',
}

export interface SpeechError {
  code: SpeechErrorCode | string;
  message: string;
}

export interface SpeechToTextOptions {
  language: string;
}

export interface PermissionOptions {
  title?: string;
  message?: string;
  buttonNeutral?: string;
  buttonNegative?: string;
  buttonPositive?: string;
}

export async function start(options: SpeechToTextOptions): Promise<void> {
  const language = options.language;
  return SpeechToTextModule.start(language);
}

export async function stop(): Promise<void> {
  return SpeechToTextModule.stop();
}

export async function requestPermissions(
  options?: PermissionOptions
): Promise<boolean> {
  if (Platform.OS === 'android') {
    try {
      const granted = await PermissionsAndroid.request(
        PermissionsAndroid.PERMISSIONS.RECORD_AUDIO,
        {
          title: options?.title ?? 'Microphone Permission',
          message:
            options?.message ??
            'This app needs access to your microphone to record audio.',
          buttonNeutral: options?.buttonNeutral ?? 'Ask Me Later',
          buttonNegative: options?.buttonNegative ?? 'Cancel',
          buttonPositive: options?.buttonPositive ?? 'OK',
        }
      );
      return granted === PermissionsAndroid.RESULTS.GRANTED;
    } catch (err) {
      console.warn(err);
      return false;
    }
  } else {
    return SpeechToTextModule.requestPermissions();
  }
}

export async function isAvailable(): Promise<boolean> {
  return SpeechToTextModule.isAvailable();
}

export function addSpeechResultListener(
  callback: (result: SpeechResult) => void
): EmitterSubscription {
  return eventEmitter.addListener('onSpeechResult', callback);
}

export function addSpeechErrorListener(
  callback: (error: SpeechError) => void
): EmitterSubscription {
  return eventEmitter.addListener('onSpeechError', callback);
}

export function addSpeechEndListener(
  callback: () => void
): EmitterSubscription {
  return eventEmitter.addListener('onSpeechEnd', callback);
}
