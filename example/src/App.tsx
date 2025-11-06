import { useState, useEffect } from 'react';
import {
  StyleSheet,
  View,
  Text,
  TouchableOpacity,
  SafeAreaView,
  Alert,
} from 'react-native';
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
  const [transcript, setTranscript] = useState<string>('');
  const [isListening, setIsListening] = useState(false);
  const [confidence, setConfidence] = useState<number>(0);
  const [listenerStatus, setListenerStatus] = useState('Not attached');

  useEffect(() => {
    console.log('📌 Setting up listeners...');
    setListenerStatus('Attaching...');

    const resultListener = addSpeechResultListener((result: SpeechResult) => {
      console.log('✅ RECEIVED Result:', result);

      if (result.transcript) {
        setTranscript(result.transcript);
        setConfidence(result.confidence);
      }
    });

    const errorListener = addSpeechErrorListener((error) => {
      console.log('❌ RECEIVED Error:', error);
      Alert.alert('Error', `${error.code}: ${error.message}`);
      setIsListening(false);
    });

    const endListener = addSpeechEndListener(() => {
      console.log('🏁 RECEIVED End');
      setIsListening(false);
    });

    setListenerStatus('Attached ✅');
    console.log('✅ Listeners attached');

    return () => {
      console.log('🧹 Cleaning up listeners...');
      resultListener.remove();
      errorListener.remove();
      endListener.remove();
      setListenerStatus('Removed');
    };
  }, []);

  const handleStart = async () => {
    try {
      console.log('🎤 Starting...');

      const available = await isAvailable();
      console.log('Available:', available);

      if (!available) {
        Alert.alert('Error', 'Speech recognition not available');
        return;
      }

      const hasPermission = await requestPermissions();
      console.log('Permission:', hasPermission);

      if (!hasPermission) {
        Alert.alert(
          'Permission Denied',
          'Microphone or speech recognition denied'
        );
        return;
      }

      await start({ language: 'en-US' });
      setIsListening(true);
      setTranscript('🎤 Listening...');
      setConfidence(0);
      console.log('✅ Started recording');
    } catch (error) {
      console.error('❌ Start error:', error);
      Alert.alert('Error', String(error));
    }
  };

  const handleStop = async () => {
    try {
      console.log('⏹ Stopping...');
      await stop();
      console.log('✅ Stopped recording');
    } catch (error) {
      console.error('❌ Stop error:', error);
      Alert.alert('Error', String(error));
      setIsListening(false);
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.content}>
        <Text style={styles.title}>Speech to Text</Text>

        <Text style={styles.debug}>Listeners: {listenerStatus}</Text>

        <View style={styles.resultContainer}>
          <Text style={styles.label}>Transcription:</Text>
          <Text style={styles.transcript}>
            {transcript || 'Press the button to start speaking'}
          </Text>

          {confidence > 0 && (
            <Text style={styles.confidence}>
              Confidence: {(confidence * 100).toFixed(0)}%
            </Text>
          )}
        </View>

        <TouchableOpacity
          style={[
            styles.button,
            isListening ? styles.buttonStop : styles.buttonStart,
          ]}
          onPress={isListening ? handleStop : handleStart}
          activeOpacity={0.7}
        >
          <Text style={styles.buttonText}>
            {isListening ? '⏹ Stop' : '🎤 Start'}
          </Text>
        </TouchableOpacity>

        <Text style={styles.hint}>
          {isListening
            ? 'Speak now... (real-time transcription)'
            : 'Language: English (en-US)'}
        </Text>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  content: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    marginBottom: 20,
    color: '#333',
  },
  debug: {
    fontSize: 12,
    color: '#666',
    marginBottom: 20,
  },
  resultContainer: {
    width: '100%',
    backgroundColor: 'white',
    borderRadius: 12,
    padding: 20,
    marginBottom: 30,
    minHeight: 150,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  label: {
    fontSize: 14,
    fontWeight: '600',
    color: '#666',
    marginBottom: 10,
  },
  transcript: {
    fontSize: 18,
    color: '#333',
    lineHeight: 26,
  },
  confidence: {
    fontSize: 14,
    color: '#4CAF50',
    marginTop: 10,
    fontWeight: '600',
  },
  button: {
    paddingHorizontal: 40,
    paddingVertical: 16,
    borderRadius: 25,
    minWidth: 200,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.2,
    shadowRadius: 4,
    elevation: 4,
  },
  buttonStart: {
    backgroundColor: '#4CAF50',
  },
  buttonStop: {
    backgroundColor: '#f44336',
  },
  buttonText: {
    color: 'white',
    fontSize: 18,
    fontWeight: 'bold',
  },
  hint: {
    marginTop: 20,
    fontSize: 14,
    color: '#999',
    fontStyle: 'italic',
  },
});
