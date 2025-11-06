# @dbkable/react-native-speech-to-text

[![npm version](https://img.shields.io/npm/v/@dbkable/react-native-speech-to-text.svg)](https://www.npmjs.com/package/@dbkable/react-native-speech-to-text)
[![npm downloads](https://img.shields.io/npm/dm/@dbkable/react-native-speech-to-text.svg)](https://www.npmjs.com/package/@dbkable/react-native-speech-to-text)
[![license](https://img.shields.io/npm/l/@dbkable/react-native-speech-to-text.svg)](https://github.com/adelbeke/react-native-speech-to-text/blob/main/LICENSE)

A powerful, easy-to-use React Native library for real-time speech-to-text conversion. Built with the New Architecture (Turbo Modules) for optimal performance on both iOS and Android.

## ✨ Features

- 🎤 **Real-time transcription** with partial results as you speak
- 📱 **Cross-platform** support for iOS and Android
- 🎯 **Confidence scores** for transcription accuracy
- 🌍 **Multi-language** support
- ⚡ **Event-driven** architecture with listeners
- 🔒 **Built-in permission handling**
- 🏗️ **New Architecture** ready (Turbo Modules)
- 📝 **TypeScript** definitions included

## 📱 Demo

| iOS                                                                                                       | Android                                                                                                   |
| --------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| <video src="https://github.com/user-attachments/assets/e48938ca-87a5-4343-ab76-cecc91b8380f" width="300"> | <video src="https://github.com/user-attachments/assets/2fbf41db-bf2d-4759-9181-0b8376a96dc1" width="300"> |

## 📦 Installation

```bash
npm install @dbkable/react-native-speech-to-text
```

or

```bash
yarn add @dbkable/react-native-speech-to-text
```

### iOS Setup

Install pods:

```bash
cd ios && pod install
```

Add the following to your `Info.plist`:

```xml
<key>NSSpeechRecognitionUsageDescription</key>
<string>This app needs speech recognition to convert your voice to text</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to record your voice</string>
```

### Android Setup

Add the following permission to your `AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
  <uses-permission android:name="android.permission.RECORD_AUDIO" />
</manifest>
```

The package handles runtime permission requests automatically.

## 🚀 Quick Start

```typescript
import { useState, useEffect } from 'react';
import {
  start,
  stop,
  requestPermissions,
  isAvailable,
  addSpeechResultListener,
  addSpeechErrorListener,
  addSpeechEndListener,
  type SpeechResult,
} from '@dbkable/react-native-speech-to-text';

export default function App() {
  const [transcript, setTranscript] = useState('');
  const [isListening, setIsListening] = useState(false);

  useEffect(() => {
    // Listen for results
    const resultListener = addSpeechResultListener((result: SpeechResult) => {
      setTranscript(result.transcript);
      console.log('Confidence:', result.confidence);
    });

    // Listen for errors
    const errorListener = addSpeechErrorListener((error) => {
      console.error('Speech error:', error);
      setIsListening(false);
    });

    // Listen for end of speech
    const endListener = addSpeechEndListener(() => {
      setIsListening(false);
    });

    // Cleanup
    return () => {
      resultListener.remove();
      errorListener.remove();
      endListener.remove();
    };
  }, []);

  const handleStart = async () => {
    try {
      const available = await isAvailable();
      if (!available) {
        alert('Speech recognition not available');
        return;
      }

      const hasPermission = await requestPermissions();
      if (!hasPermission) {
        alert('Permission denied');
        return;
      }

      await start({ language: 'en-US' });
      setIsListening(true);
    } catch (error) {
      console.error(error);
    }
  };

  const handleStop = async () => {
    try {
      await stop();
    } catch (error) {
      console.error(error);
    }
  };

  return (
    <View>
      <Text>{transcript || 'Press start to begin'}</Text>
      <Button
        title={isListening ? 'Stop' : 'Start'}
        onPress={isListening ? handleStop : handleStart}
      />
    </View>
  );
}
```

## 📚 API Reference

### Methods

#### `start(options: SpeechToTextOptions): Promise<void>`

Starts speech recognition.

```typescript
await start({ language: 'en-US' });
```

**Options:**

- `language` (string, required): Language code (e.g., "en-US", "fr-FR", "es-ES", "de-DE")

**Throws:**

- `PERMISSION_DENIED`: User denied permissions
- `NOT_AVAILABLE`: Speech recognition not available
- `START_FAILED`: Failed to start recognition

---

#### `stop(): Promise<void>`

Stops speech recognition and sends the final transcript.

```typescript
await stop();
```

---

#### `requestPermissions(options?: PermissionOptions): Promise<boolean>`

Requests necessary permissions for speech recognition.

```typescript
const granted = await requestPermissions({
  title: 'Microphone Permission',
  message: 'This app needs access to your microphone for speech recognition',
  buttonPositive: 'OK',
});
```

**Options (Android only):**

- `title` (string, optional): Dialog title
- `message` (string, optional): Dialog message
- `buttonNeutral` (string, optional): Neutral button text
- `buttonNegative` (string, optional): Negative button text
- `buttonPositive` (string, optional): Positive button text

**Returns:** `boolean` - `true` if permission granted, `false` otherwise

---

#### `isAvailable(): Promise<boolean>`

Checks if speech recognition is available on the device.

```typescript
const available = await isAvailable();
if (!available) {
  console.log('Speech recognition not supported');
}
```

**Returns:** `boolean`

---

### Event Listeners

#### `addSpeechResultListener(callback: (result: SpeechResult) => void): EmitterSubscription`

Listens for transcription results (both partial and final).

```typescript
const listener = addSpeechResultListener((result) => {
  console.log('Transcript:', result.transcript);
  console.log('Confidence:', result.confidence);
  console.log('Is final:', result.isFinal);
});

// Don't forget to remove the listener
listener.remove();
```

**SpeechResult:**

- `transcript` (string): The recognized text
- `confidence` (number): Confidence score from 0.0 to 1.0
- `isFinal` (boolean): `true` for final result, `false` for partial

---

#### `addSpeechErrorListener(callback: (error: SpeechError) => void): EmitterSubscription`

Listens for error events.

```typescript
const listener = addSpeechErrorListener((error) => {
  console.error('Error code:', error.code);
  console.error('Error message:', error.message);
});

listener.remove();
```

**SpeechError:**

- `code` (string): Error code (see [Error Codes](#error-codes))
- `message` (string): Human-readable error message

---

#### `addSpeechEndListener(callback: () => void): EmitterSubscription`

Called when speech recognition ends.

```typescript
const listener = addSpeechEndListener(() => {
  console.log('Speech recognition ended');
});

listener.remove();
```

---

### Types

```typescript
interface SpeechToTextOptions {
  language: string; // e.g., "en-US", "fr-FR", "es-ES"
}

interface PermissionOptions {
  title?: string;
  message?: string;
  buttonNeutral?: string;
  buttonNegative?: string;
  buttonPositive?: string;
}

interface SpeechResult {
  transcript: string;
  confidence: number;
  isFinal: boolean;
}

interface SpeechError {
  code: SpeechErrorCode | string;
  message: string;
}

enum SpeechErrorCode {
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
```

## 🌍 Supported Languages

You can use any standard locale identifier. Here are some examples:

- English: `en-US`, `en-GB`, `en-AU`
- French: `fr-FR`, `fr-CA`
- Spanish: `es-ES`, `es-MX`
- German: `de-DE`
- Italian: `it-IT`
- Portuguese: `pt-BR`, `pt-PT`
- Japanese: `ja-JP`
- Chinese: `zh-CN`, `zh-TW`
- Korean: `ko-KR`
- Arabic: `ar-SA`

Availability depends on the device and platform. Use `isAvailable()` to check.

## 🔧 Troubleshooting

### "Permission denied" error

**iOS:**

- Make sure you've added `NSSpeechRecognitionUsageDescription` and `NSMicrophoneUsageDescription` to your `Info.plist`
- Check that the user granted permissions in Settings > Your App

**Android:**

- Ensure `RECORD_AUDIO` permission is in `AndroidManifest.xml`
- Call `requestPermissions()` before `start()`

---

### "Speech recognition not available"

- **iOS**: Speech recognition requires iOS 10+ and is not available in the simulator for some iOS versions. Test on a real device.
- **Android**: Ensure Google app or speech recognition service is installed and up to date.
- Some older devices may not support speech recognition.

---

### No partial results showing

- Partial results are enabled by default on both platforms
- On Android, partial results appear after a short delay
- If you're only seeing final results, check that you're handling the `isFinal` flag correctly

---

### Recognition stops automatically

- **iOS**: May stop automatically after detecting silence
- **Android**: Configured with 2-second pause detection and 10-second minimum recording
- Call `start()` again to restart recognition

---

### Low confidence scores

- Speak clearly and in a quiet environment
- Ensure the device microphone is not obstructed
- Try a different language/locale that better matches the speaker's accent

---

### Network errors

Some speech recognition services require internet connectivity:

- **iOS**: On-device recognition available on iOS 13+ for some languages
- **Android**: Depends on the device's speech recognition provider

Ensure the device has internet access for best results.

## 🤝 Contributing

We welcome contributions! Here's how to get started:

1. **Fork the repository** on GitHub
2. **Clone your fork** locally
3. **Create a branch** for your feature: `git checkout -b my-feature`
4. **Make your changes** and add tests if applicable
5. **Test thoroughly** on both iOS and Android
6. **Commit your changes**: `git commit -am 'feat: add amazing feature'` (follow [Conventional Commits](https://www.conventionalcommits.org/))
7. **Push to your fork**: `git push origin my-feature`
8. **Open a Pull Request** on GitHub

### Development Setup

```bash
# Clone the repo
git clone https://github.com/adelbeke/react-native-speech-to-text.git
cd react-native-speech-to-text

# Install dependencies
yarn install

# Run the example app
yarn example ios
# or
yarn example android
```

### Code Style

This project uses ESLint and Prettier. Run:

```bash
yarn lint
yarn typescript
```

For more details, see [CONTRIBUTING.md](CONTRIBUTING.md).

## 📄 License

MIT © Arthur Delbeke

## 🙏 Acknowledgments

Built with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)

## 🔗 Links

- [GitHub Repository](https://github.com/adelbeke/react-native-speech-to-text)
- [npm Package](https://www.npmjs.com/package/@dbkable/react-native-speech-to-text)
- [Report Issues](https://github.com/adelbeke/react-native-speech-to-text/issues)

---

Made with ❤️ for the React Native community
