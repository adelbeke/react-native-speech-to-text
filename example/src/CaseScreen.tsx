import { useEffect, useRef, useState } from 'react';
import {
  BackHandler,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import {
  addAudioMeterUpdateListener,
  addSpeechEndListener,
  addSpeechErrorListener,
  addSpeechResultListener,
  isAvailable,
  isOnDeviceAvailable,
  requestPermissions,
  start,
  stop,
} from '@dbkable/react-native-speech-to-text';
import type { TestCase } from './cases';

const TIMER_INTERVAL_MS = 1000;

function formatError(error: unknown): string {
  const { code, message } = error as { code?: string; message?: string };
  return code ? `${code}: ${message}` : String(error);
}

export function CaseScreen({
  testCase,
  onBack,
}: {
  testCase: TestCase;
  onBack: () => void;
}) {
  const [language, setLanguage] = useState(testCase.language);
  const [onDeviceAvailable, setOnDeviceAvailable] = useState<string>('…');
  const [transcript, setTranscript] = useState('');
  const [confidence, setConfidence] = useState(0);
  const [meterLevel, setMeterLevel] = useState(0);
  const [isListening, setIsListening] = useState(false);
  const [elapsedSeconds, setElapsedSeconds] = useState(0);
  const [events, setEvents] = useState<string[]>([]);
  const [doneSteps, setDoneSteps] = useState<Set<number>>(new Set());
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const log = (line: string) =>
    setEvents((previous) => [
      `${new Date().toLocaleTimeString()} ${line}`,
      ...previous,
    ]);

  const stopTimer = () => {
    if (timerRef.current) clearInterval(timerRef.current);
    timerRef.current = null;
  };

  useEffect(() => {
    const subscription = BackHandler.addEventListener(
      'hardwareBackPress',
      () => {
        onBack();
        return true;
      }
    );
    return () => subscription.remove();
  }, [onBack]);

  useEffect(() => {
    isOnDeviceAvailable(language)
      .then((available) => setOnDeviceAvailable(String(available)))
      .catch((error) => setOnDeviceAvailable(formatError(error)));
  }, [language]);

  useEffect(() => {
    const subscriptions = [
      addSpeechResultListener((result) => {
        setTranscript(result.transcript);
        setConfidence(result.confidence);
        if (result.isFinal) log('final result');
      }),
      addSpeechErrorListener((error) => {
        log(`error event ${error.code}: ${error.message}`);
        setIsListening(false);
        stopTimer();
      }),
      addSpeechEndListener(() => {
        log('end event');
        setIsListening(false);
        setMeterLevel(0);
        stopTimer();
      }),
      addAudioMeterUpdateListener((update) => setMeterLevel(update.level)),
    ];
    return () => {
      subscriptions.forEach((subscription) => subscription.remove());
      stopTimer();
      stop().catch(() => {});
    };
  }, []);

  const handleStart = async () => {
    try {
      log(`isAvailable: ${await isAvailable()}`);
      if (!(await requestPermissions())) {
        log('permission denied');
        return;
      }
      setTranscript('');
      setConfidence(0);
      setElapsedSeconds(0);
      await start({
        language,
        onDevice: testCase.onDevice,
        continuous: testCase.continuous,
      });
      log(
        `started (${language}, onDevice: ${testCase.onDevice}, continuous: ${testCase.continuous ?? false})`
      );
      setIsListening(true);
      timerRef.current = setInterval(
        () => setElapsedSeconds((seconds) => seconds + 1),
        TIMER_INTERVAL_MS
      );
    } catch (error) {
      log(`start rejected ${formatError(error)}`);
    }
  };

  const handleStop = async () => {
    try {
      await stop();
      log('stopped');
    } catch (error) {
      log(`stop rejected ${formatError(error)}`);
      setIsListening(false);
    }
    stopTimer();
  };

  const toggleStep = (index: number) =>
    setDoneSteps((previous) => {
      const next = new Set(previous);
      if (next.has(index)) next.delete(index);
      else next.add(index);
      return next;
    });

  return (
    <ScrollView contentContainerStyle={styles.content}>
      <TouchableOpacity onPress={onBack} accessibilityRole="button">
        <Text style={styles.back}>‹ Cases</Text>
      </TouchableOpacity>
      <Text style={styles.title}>{testCase.title}</Text>

      <Text style={styles.section}>Steps</Text>
      {testCase.steps.map((step, index) => (
        <TouchableOpacity
          key={step}
          style={styles.step}
          onPress={() => toggleStep(index)}
          accessibilityRole="checkbox"
          accessibilityState={{ checked: doneSteps.has(index) }}
        >
          <Text style={styles.checkbox}>
            {doneSteps.has(index) ? '☑' : '☐'}
          </Text>
          <Text style={[styles.stepText, doneSteps.has(index) && styles.done]}>
            {index + 1}. {step}
          </Text>
        </TouchableOpacity>
      ))}
      <Text style={styles.expected}>Expected: {testCase.expected}</Text>

      <Text style={styles.section}>Setup</Text>
      <View style={styles.row}>
        <Text style={styles.label}>Language</Text>
        <TextInput
          style={styles.input}
          value={language}
          onChangeText={setLanguage}
          autoCapitalize="none"
          autoCorrect={false}
          editable={!isListening}
        />
      </View>
      <Text style={styles.label}>onDevice: {String(testCase.onDevice)}</Text>
      <Text style={styles.label}>On-device available: {onDeviceAvailable}</Text>

      <Text style={styles.section}>Recognition</Text>
      <View style={styles.card}>
        <Text style={styles.transcript}>
          {transcript || (isListening ? 'Listening…' : 'No transcript yet')}
        </Text>
        {confidence > 0 && (
          <Text style={styles.label}>
            Confidence: {(confidence * 100).toFixed(0)}%
          </Text>
        )}
        <Text style={styles.label}>Elapsed: {elapsedSeconds}s</Text>
        <View style={styles.meter}>
          <View
            style={[
              styles.meterFill,
              { width: `${Math.round(meterLevel * 100)}%` },
            ]}
          />
        </View>
      </View>
      <TouchableOpacity
        style={[styles.button, isListening ? styles.stop : styles.start]}
        onPress={isListening ? handleStop : handleStart}
        accessibilityRole="button"
      >
        <Text style={styles.buttonText}>
          {isListening ? '⏹ Stop' : '🎤 Start'}
        </Text>
      </TouchableOpacity>

      <Text style={styles.section}>Events</Text>
      {events.map((event, index) => (
        <Text key={`${index}-${event}`} style={styles.event}>
          {event}
        </Text>
      ))}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  content: { padding: 20, paddingBottom: 60 },
  back: { fontSize: 17, color: '#007AFF', marginBottom: 12 },
  title: { fontSize: 24, fontWeight: 'bold', color: '#333' },
  section: {
    fontSize: 13,
    fontWeight: '700',
    color: '#888',
    textTransform: 'uppercase',
    marginTop: 24,
    marginBottom: 8,
  },
  step: { flexDirection: 'row', paddingVertical: 6 },
  checkbox: { fontSize: 18, marginRight: 8 },
  stepText: { flex: 1, fontSize: 15, color: '#333' },
  done: { color: '#aaa', textDecorationLine: 'line-through' },
  expected: { marginTop: 8, fontSize: 14, color: '#2E7D32', fontWeight: '600' },
  row: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  label: { fontSize: 14, color: '#555', marginVertical: 4 },
  input: {
    flex: 1,
    borderWidth: 1,
    borderColor: '#ccc',
    borderRadius: 8,
    padding: 8,
    fontSize: 15,
    backgroundColor: 'white',
  },
  card: {
    backgroundColor: 'white',
    borderRadius: 12,
    padding: 16,
    minHeight: 120,
  },
  transcript: { fontSize: 18, color: '#333', lineHeight: 26, marginBottom: 8 },
  meter: {
    height: 8,
    backgroundColor: '#e0e0e0',
    borderRadius: 4,
    marginTop: 8,
    overflow: 'hidden',
  },
  meterFill: { height: '100%', backgroundColor: '#4CAF50' },
  button: {
    marginTop: 16,
    paddingVertical: 16,
    borderRadius: 25,
    alignItems: 'center',
  },
  start: { backgroundColor: '#4CAF50' },
  stop: { backgroundColor: '#f44336' },
  buttonText: { color: 'white', fontSize: 18, fontWeight: 'bold' },
  event: {
    fontSize: 12,
    color: '#555',
    fontFamily: 'Menlo',
    marginVertical: 2,
  },
});
