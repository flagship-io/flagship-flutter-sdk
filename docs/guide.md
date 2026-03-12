
ABTasty QA Assistant - React Native Integration Guide
This guide covers integration of the ABTasty QA Assistant into React Native applications. For usage instructions, see the [QA Usage Guide](./qa-use.md).


1. Overview
What is ABTasty QA Assistant?
The ABTasty QA Assistant is a visual testing tool for React Native applications that integrates with ABTasty Feature Experimentation. It provides a floating UI overlay that allows developers and QA engineers to test campaign variations and feature flags without backend changes or app redeployment.
Key Features
Force Variations: Instantly switch between campaign variations
Force Allocation: Enable variation forcing for rejected campaigns (allows testing without meeting targeting)
Hide Campaign: Hide accepted campaigns to test exclusion scenarios
Real-time Event Monitoring: Track all SDK events for integration verification
Context Inspection: View visitor data and targeting rules
Search & Filter: Quickly find specific campaigns and events
Note: Forced allocations, variations, and hidden campaigns are temporary and reset when you disable QA mode or restart the app. Everything returns to natural allocation automatically.
Prerequisites


2. Installation
Step 1: Install Flagship SDK (if not already installed)
# Using npm
npm install @flagship.io/react-native-sdk

# Using yarn
yarn add @flagship.io/react-native-sdk
Step 2: Install the Package
# Using npm
npm install @abtasty/qa-assistant-react-native

# Using yarn
yarn add @abtasty/qa-assistant-react-native
Dependencies
The QA Assistant has the following dependencies:
Peer Dependencies (must be installed separately):
@flagship.io/react-native-sdk >= 5.0.2
react >= 18.0.0
react-native >= 0.70.0

3. Integration
Quick Start
Add the QA Assistant to your app in two steps:
Step 1: Enable QA Mode in FlagshipProvider
import { FlagshipProvider } from '@flagship.io/react-native-sdk';
import { QAAssistant } from '@abtasty/qa-assistant-react-native';

export default function App() {
  return (
    <FlagshipProvider
      envId="YOUR_ENV_ID"
      apiKey="YOUR_API_KEY"
      isQAModeEnabled={true}  // REQUIRED for QA Assistant
      visitorData={{
        id: 'visitor_id',
        hasConsented: true,
        context: { platform: 'mobile' }
      }}
    >
      <YourApp />
      <QAAssistant />
    </FlagshipProvider>
  );
}
CRITICAL: The isQAModeEnabled={true} prop is required. Without it, the QA Assistant will not render.
Step 2: Development-Only Usage
Ensure the QA Assistant only appears in development builds:
export default function App() {
  return (
    <FlagshipProvider {...props}>
      <YourApp />
      {__DEV__ && <QAAssistant />}
    </FlagshipProvider>
  );
}
Configuration Options
Customize the QA Assistant appearance and behavior:
<QAAssistant
  config={{
    position: "bottom-right",  // "top-right" | "top-left" | "bottom-right" | "bottom-left"
  }}
/>
Available Positions:
"top-right" - Top right corner
"top-left" - Top left corner
"bottom-right" - Bottom right corner (default)
"bottom-left" - Bottom left corner
Complete Example
import React from 'react';
import { StyleSheet, View, Text } from 'react-native';
import { FlagshipProvider, useFsFlag } from '@flagship.io/react-native-sdk';
import { QAAssistant } from '@abtasty/qa-assistant-react-native';

function MyApp() {
  const welcomeMessage = useFsFlag('welcome_message');
  const showNewFeature = useFsFlag('show_new_feature');

  return (
    <View style={styles.container}>
      <Text style={styles.title}>
        {welcomeMessage.getValue('Welcome!')}
      </Text>
      {showNewFeature.getValue(false) && (
        <Text>New Feature Enabled</Text>
      )}
    </View>
  );
}

export default function App() {
  return (
    <FlagshipProvider
      envId="YOUR_ENV_ID"
      apiKey="YOUR_API_KEY"
      isQAModeEnabled={true}
      visitorData={{
        id: 'test_visitor_123',
        hasConsented: true,
        context: {
          platform: 'mobile',
          userType: 'free'
        }
      }}
    >
      <MyApp />
      {__DEV__ && (
        <QAAssistant config={{ position: "bottom-right" }} />
      )}
    </FlagshipProvider>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 20 },
  title: { fontSize: 24, fontWeight: 'bold' }
});
Best Practices
DO:
Always use isQAModeEnabled={true} in FlagshipProvider
Place QAAssistant inside FlagshipProvider
Use conditional rendering (__DEV__) to exclude from production
Use SDK hooks to ensure flag changes are reactive
DON'T:
Never include QA Assistant in production builds
Don't place QA Assistant outside FlagshipProvider
Don't hardcode flag values - always use SDK hooks

4. Troubleshooting & FAQ
Common Issues
QA Assistant Not Showing
Checklist:
Verify isQAModeEnabled is set to true
<FlagshipProvider isQAModeEnabled={true} {...props}>
Ensure QAAssistant is inside FlagshipProvider
<FlagshipProvider>
  <App />
  <QAAssistant />  {/* ✓ Correct placement */}
</FlagshipProvider>
Check conditional rendering
// Verify __DEV__ is true
console.log('__DEV__:', __DEV__);
{__DEV__ && <QAAssistant />}
Clear cache and reinstall
rm -rf node_modules && yarn install
npx react-native start --reset-cache

Console Warnings
Warning: "Not able to access Flagship SDK instance"
Cause 1: QAAssistant is not a direct child of FlagshipProvider.
Solution: Move QAAssistant inside FlagshipProvider.
// ✗ Wrong
<>
  <FlagshipProvider {...props}>
    <App />
  </FlagshipProvider>
  <QAAssistant />
</>

// ✓ Correct
<FlagshipProvider {...props}>
  <App />
  <QAAssistant />
</FlagshipProvider>
Cause 2: Flagship React Native SDK version is incompatible (< 5.0.2).
Solution: Update to SDK version >= 5.0.2:
npm install @flagship.io/react-native-sdk@latest
# or
yarn add @flagship.io/react-native-sdk@latest

Warning: "QA mode not enabled"
Solution: Add isQAModeEnabled={true} to FlagshipProvider.

Warning: "No valid envId configured"
Solution: Verify envId prop is set correctly in FlagshipProvider.

Campaigns Not Appearing
Possible Causes:
No campaigns configured - Check ABTasty platform
Network issues - Verify bucketing.json loads correctly
Wrong environment - Ensure using correct envId
SDK initialization - Wait a few seconds after app launch
Forced Variations Not Applying
Solutions:
Use SDK hooks - Ensure you're using useFsFlag():
// ✗ Wrong - hardcoded
const message = "Welcome";

// ✓ Correct - using SDK
const messageFlag = useFsFlag('welcome_message');
const message = messageFlag.getValue('Welcome');
Verify correct variation - Check that the forced variation contains the expected flag modifications
Reset and retry - Clear forced variations and try again

Floating Button Overlapping UI
Solutions:
Changeposition:
<QAAssistant config={{ position: "top-left" }} />

Frequently Asked Questions
Q: Do forced allocations persist after app restart? A: NO! All forced allocations, hidden campaigns, and variations are temporary and reset automatically when:
You disable QA mode (set isQAModeEnabled={false})
You restart the app
This is by design to ensure a clean state and prevent accidental forced states in production.
Q: Can I force multiple campaigns at once? A: Yes, each forced variation, allocation, and hidden campaign is independent.
Q: What's the difference between forcing a variation, allocation, and hiding a campaign?

Q: Can I use QA Assistant in production? A: NO! Always use conditional rendering ({__DEV__ && <QAAssistant />}) to exclude it from production.
Q: Does QA Assistant work offline? A: Initial load requires network to fetch campaigns. After that, it works offline with cached data.
Q: Can I force variations programmatically? A: QA Assistant is for manual testing. For automated tests, use Flagship SDK methods directly with controlled context values.

Additional Resources
Usage Guide: See qa-use.md for detailed usage instructions
Flagship SDK Documentation: https://docs.developers.flagship.io/
Support: For issues or questions, contact ABTasty support