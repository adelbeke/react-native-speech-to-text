import { NativeModules } from 'react-native';
import NativeSpeechToText from '../NativeReactNativeSpeechToText';

jest.mock('../NativeReactNativeSpeechToText', () => ({
  __esModule: true,
  default: { start: jest.fn(() => Promise.resolve()) },
}));

NativeModules.ReactNativeSpeechToText = {
  addListener: jest.fn(),
  removeListeners: jest.fn(),
};

const nativeStart = NativeSpeechToText.start as jest.Mock;

async function when_starting(options: {
  language: string;
  continuous?: boolean;
}) {
  const { start } = await import('../index');
  await start(options);
}

describe('start', () => {
  beforeEach(() => {
    nativeStart.mockClear();
  });

  it('does not ask the native module for continuous listening by default', async () => {
    // GIVEN only a language
    const options = { language: 'en-US' };

    // WHEN starting recognition
    await when_starting(options);

    // THEN continuous listening is off
    expect(nativeStart).toHaveBeenCalledWith('en-US', false);
  });

  it('forwards continuous listening to the native module when requested', async () => {
    // GIVEN continuous listening is requested
    const options = { language: 'fr-FR', continuous: true };

    // WHEN starting recognition
    await when_starting(options);

    // THEN the native module receives it
    expect(nativeStart).toHaveBeenCalledWith('fr-FR', true);
  });
});
