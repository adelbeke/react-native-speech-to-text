import NativeSpeechToText from '../NativeReactNativeSpeechToText';
import { isOnDeviceAvailable, start } from '../index';

jest.mock('react-native/Libraries/EventEmitter/NativeEventEmitter');

jest.mock('../NativeReactNativeSpeechToText', () => ({
  __esModule: true,
  default: {
    start: jest.fn(() => Promise.resolve()),
    isOnDeviceAvailable: jest.fn(() => Promise.resolve(true)),
    addListener: jest.fn(),
    removeListeners: jest.fn(),
  },
}));

const nativeModule = jest.mocked(NativeSpeechToText);

describe('start', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('passes onDevice true to the native module when requested', async () => {
    // WHEN
    await start({ language: 'fr-FR', onDevice: true });

    // THEN
    expect(nativeModule.start).toHaveBeenCalledWith('fr-FR', true, false);
  });

  it('passes onDevice false to the native module when omitted', async () => {
    // WHEN
    await start({ language: 'en-US' });

    // THEN
    expect(nativeModule.start).toHaveBeenCalledWith('en-US', false, false);
  });

  it('passes continuous true to the native module when requested', async () => {
    // WHEN
    await start({ language: 'fr-FR', continuous: true });

    // THEN
    expect(nativeModule.start).toHaveBeenCalledWith('fr-FR', false, true);
  });
});

describe('isOnDeviceAvailable', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('asks the native module for the given language', async () => {
    // WHEN
    const actual = await isOnDeviceAvailable('fr-FR');

    // THEN
    expect(nativeModule.isOnDeviceAvailable).toHaveBeenCalledWith('fr-FR');
    expect(actual).toBe(true);
  });
});
