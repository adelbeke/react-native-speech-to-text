import { useState } from 'react';
import {
  FlatList,
  Platform,
  SafeAreaView,
  StyleSheet,
  Text,
  TouchableOpacity,
} from 'react-native';
import { TEST_CASES, type TestCase } from './cases';
import { CaseScreen } from './CaseScreen';

const CURRENT_PLATFORM = Platform.OS === 'ios' ? 'iOS' : 'Android';
const PLATFORM_CASES = TEST_CASES.filter(
  (testCase) =>
    testCase.platform === 'All' || testCase.platform === CURRENT_PLATFORM
);

export default function App() {
  const [selectedCase, setSelectedCase] = useState<TestCase | null>(null);

  return (
    <SafeAreaView style={styles.container}>
      {selectedCase ? (
        <CaseScreen
          testCase={selectedCase}
          onBack={() => setSelectedCase(null)}
        />
      ) : (
        <FlatList
          data={PLATFORM_CASES}
          keyExtractor={(testCase) => testCase.id}
          contentContainerStyle={styles.list}
          ListHeaderComponent={<Text style={styles.title}>Test cases</Text>}
          renderItem={({ item }) => (
            <TouchableOpacity
              style={styles.item}
              onPress={() => setSelectedCase(item)}
              accessibilityRole="button"
            >
              <Text style={styles.itemTitle}>{item.title}</Text>
              <Text style={styles.itemMeta}>
                {item.platform} · {item.language} · onDevice:{' '}
                {String(item.onDevice)} · continuous:{' '}
                {String(item.continuous ?? false)}
              </Text>
            </TouchableOpacity>
          )}
        />
      )}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#f5f5f5' },
  list: { padding: 20 },
  title: { fontSize: 28, fontWeight: 'bold', color: '#333', marginBottom: 16 },
  item: {
    backgroundColor: 'white',
    borderRadius: 12,
    padding: 16,
    marginBottom: 10,
  },
  itemTitle: { fontSize: 17, fontWeight: '600', color: '#333' },
  itemMeta: { fontSize: 13, color: '#888', marginTop: 4 },
});
