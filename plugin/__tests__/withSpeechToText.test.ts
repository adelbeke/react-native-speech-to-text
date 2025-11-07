import withSpeechToText from '../src';
import type { ExpoConfig } from '@expo/config';

describe('withSpeechToText', () => {
  it('should configure plugin with default properties', () => {
    const config: ExpoConfig = {
      name: 'test-app',
      slug: 'test-app',
      platforms: ['android', 'ios'],
    };

    const result = withSpeechToText(config, {});

    expect(result).toBeDefined();
    expect(result.name).toBe('test-app');
  });

  it('should configure plugin with custom properties', () => {
    const config: ExpoConfig = {
      name: 'test-app',
      slug: 'test-app',
      platforms: ['android', 'ios'],
    };

    const result = withSpeechToText(config, {
      microphonePermission: 'Custom mic permission',
      speechRecognitionPermission: 'Custom speech permission',
    });

    expect(result).toBeDefined();
  });

  it('should handle missing properties gracefully', () => {
    const config: ExpoConfig = {
      name: 'test-app',
      slug: 'test-app',
      platforms: ['android', 'ios'],
    };

    expect(() => withSpeechToText(config, {})).not.toThrow();
  });
});
