export interface TestCase {
  id: string;
  title: string;
  platform: 'iOS' | 'Android' | 'All';
  language: string;
  onDevice: boolean;
  continuous?: boolean;
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
  {
    id: 'android-pause-ends',
    title: 'Pause ends the session (control)',
    platform: 'Android',
    language: 'en-US',
    onDevice: false,
    steps: ['Tap Start and say an English sentence', 'Stay silent for 3s'],
    expected:
      'About 2s into the silence: "final result" then "end event". Compare with the next case.',
  },
  {
    id: 'android-continuous-pause',
    title: 'Continuous: pause keeps listening',
    platform: 'Android',
    language: 'en-US',
    onDevice: false,
    continuous: true,
    steps: [
      'Tap Start and say an English sentence',
      'Stay silent for 3s',
      'Say a second sentence',
      'Tap Stop',
    ],
    expected:
      'No "final result" or "end event" during the pause. The transcript keeps the first sentence and grows. After Stop: "final result" with both sentences, then "end event".',
  },
  {
    id: 'android-continuous-silent-start',
    title: 'Continuous: long silence at start',
    platform: 'Android',
    language: 'en-US',
    onDevice: false,
    continuous: true,
    steps: [
      'Tap Start and say nothing until the timer passes 8s',
      'Say an English sentence',
      'Tap Stop',
    ],
    expected:
      'No error or "end event" during the silence. The sentence appears, then "final result" and "end event" after Stop.',
  },
  {
    id: 'android-continuous-many-pauses',
    title: 'Continuous: many pauses (60s)',
    platform: 'Android',
    language: 'en-US',
    onDevice: false,
    continuous: true,
    steps: [
      'Tap Start',
      'Alternate a short sentence and 3s of silence until the timer passes 60s',
      'Tap Stop',
    ],
    expected:
      'No RECOGNIZER_BUSY or other error event. Every sentence is in the final transcript. Note if the system beeps at each pause (device-dependent, report the model).',
  },
];
