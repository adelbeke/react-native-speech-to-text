export interface TestCase {
  id: string;
  title: string;
  platform: 'iOS' | 'Android' | 'All';
  language: string;
  onDevice: boolean;
  steps: string[];
  expected: string;
}

export const TEST_CASES: TestCase[] = [
  {
    id: 'offline-fr',
    title: 'Offline on-device, fr-FR',
    platform: 'iOS',
    language: 'fr-FR',
    onDevice: true,
    steps: [
      'Turn on airplane mode and make sure Wi-Fi is OFF',
      'Check that "On-device available" shows true',
      'Tap Start and say a French sentence',
      'Tap Stop',
    ],
    expected: 'A transcript appears. No NOT_AVAILABLE error.',
  },
  {
    id: 'offline-en',
    title: 'Offline on-device, en-US',
    platform: 'iOS',
    language: 'en-US',
    onDevice: true,
    steps: [
      'Turn on airplane mode and make sure Wi-Fi is OFF',
      'Check that "On-device available" shows true',
      'Tap Start and say an English sentence',
      'Tap Stop',
    ],
    expected: 'A transcript appears. No NOT_AVAILABLE error.',
  },
  {
    id: 'long-session-server',
    title: 'Long server session (> 60s, control)',
    platform: 'iOS',
    language: 'en-US',
    onDevice: false,
    steps: [
      'Network ON (offline, iOS falls back to on-device by itself)',
      'Tap Start',
      'Keep talking until the timer passes 70s',
    ],
    expected:
      'Recognition stops around 60s (end or error event). Compare with the next case.',
  },
  {
    id: 'long-session-on-device',
    title: 'Long on-device session (> 60s)',
    platform: 'iOS',
    language: 'en-US',
    onDevice: true,
    steps: [
      'Network ON (forcing on-device only matters online)',
      'Check that "On-device available" shows true',
      'Tap Start',
      'Keep talking until the timer passes 70s',
      'Tap Stop',
    ],
    expected:
      'Recognition keeps going after 60s. If the control case stops and this one does not, onDevice works.',
  },
  {
    id: 'server-fallback',
    title: 'Server fallback (unsupported locale)',
    platform: 'iOS',
    language: 'uk-UA',
    onDevice: true,
    steps: [
      'Turn off airplane mode, network ON',
      'Check that "On-device available" shows false. If it shows true, edit the language until it shows false',
      'Tap Start and play a video in that language near the phone (e.g. Ukrainian news on YouTube)',
      'Tap Stop',
    ],
    expected: 'A transcript appears through the server. No error.',
  },
  {
    id: 'server-baseline',
    title: 'Server mode baseline (regression)',
    platform: 'All',
    language: 'en-US',
    onDevice: false,
    steps: ['Network ON', 'Tap Start and say an English sentence', 'Tap Stop'],
    expected: 'A transcript appears, same as before the change.',
  },
  {
    id: 'android-ignored',
    title: 'Android ignores onDevice',
    platform: 'Android',
    language: 'en-US',
    onDevice: true,
    steps: [
      'Run on Android, network ON',
      'Check that "On-device available" shows false',
      'Tap Start and say an English sentence',
      'Tap Stop',
    ],
    expected: 'A transcript appears. onDevice changes nothing on Android.',
  },
];
