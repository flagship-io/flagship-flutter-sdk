# QA Assistant User Guide

## Overview
The ABTasty QA Assistant helps you test campaigns and feature flags in your Flutter app. This guide covers all features and workflows.

**Related Documentation:**
- [Flutter SDK Integration Guide](./integration-guide.md)
- [Campaign Management](./campaigns.md)
- [Troubleshooting](./troubleshooting.md)

## Prerequisites
Before using the QA Assistant, ensure:
- ✅ ABTasty Flutter SDK v2.0.0 or higher installed
- ✅ QA mode enabled in your app configuration
- ✅ Active internet connection
- ✅ Valid ABTasty environment ID

## Quick Start

### Enabling QA Mode
```dart
// In your app initialization
Flagship.start(
  envId: "YOUR_ENV_ID",
  apiKey: "YOUR_API_KEY",
  qaMode: true, // Enable QA Assistant
);
```

### Opening the QA Assistant
1. Look for the floating button (default: bottom-right corner)
2. Tap to open the full-screen modal
3. Use tab navigation to explore features

⚠️ **Important**: QA mode should only be enabled in development/staging environments, never in production.

## Getting Started
Opening the QA Assistant
Look for the floating button at the configured position (default: bottom-right corner)
Tap the button to open the full-screen QA Assistant modal
Use the tab navigation at the top to switch between sections

The floating button appears as an overlay on your app
Main Interface
The QA Assistant has three main tabs:


Main interface with Campaigns, Events, and Context tabs

## Campaigns Tab

### Overview
The Campaigns tab displays all campaigns with their current status and allows you to:
- ✅ Force variations for testing
- 🔄 Force rejected campaigns to display
- 👁️ Hide accepted campaigns
- 📊 View targeting rules and traffic allocation

### Campaign Status Types

| Status | Badge Color | Description | Actions Available |
|--------|-------------|-------------|-------------------|
| **Accepted** | 🟢 Green | Naturally allocated to visitor | Force variation, Hide campaign |
| **Rejected** | 🔴 Red | Excluded by targeting/traffic | Force display |
| **Forced** | 🟡 Yellow | Manually forced to display | Force variation, Reset |
| **Hidden** | 🟡 Yellow | Manually hidden | Reset |

⚠️ **Important**: All forced states are temporary and reset when:
- You disable QA mode
- You restart the app
- You tap "Reset All" button

### Quick Actions

#### Force a Variation (Test Different Versions)
**When to use**: Test how different variations look and behave

1. Find an **Accepted** or **Forced** campaign
2. Tap campaign → **Variations** tab
3. Tap **"View"** on desired variation
4. Badge changes to **"Your version"**
5. Close QA Assistant and test
6. Reopen and tap **"Reset"** when done

#### Force an Allocation (Test Rejected Campaigns)
**When to use**: Test campaigns you're not naturally allocated to

1. Find a **Rejected** campaign
2. Tap **"Force display"** button
3. Badge changes to **"Forced"** (yellow)
4. Now you can force variations
5. Close QA Assistant and test
6. Reopen and tap **"Initial state"** when done

#### Hide a Campaign (Test Exclusion)
**When to use**: Verify app behavior when features are disabled

1. Find an **Accepted** campaign
2. Tap **"Hide"** button
3. Badge changes to **"Hidden"** (yellow)
4. Close QA Assistant and test fallback behavior
5. Reopen and tap **"Initial state"** when done

### Understanding Campaign Details

Each campaign has three tabs with detailed information:

#### Variations Tab
Shows all available variations with their feature flag values:
- **Current variation**: Shows "Your version" badge (green)
- **Other variations**: Show "View" button (or "Reset" if forced)
- **Flag values**: Displays all modifications (strings, numbers, booleans, objects)

#### Targeting Tab
Shows why the campaign is accepted or rejected:
- **Targeting groups**: Linked by OR (match ANY group)
- **Conditions**: Linked by AND (match ALL in group)
- **Status indicators**: ✅ Green for matched, ❌ Red for unmatched

**Common operators**:
- `EQUALS` / `NOT_EQUALS` - Exact match
- `CONTAINS` / `NOT_CONTAINS` - Substring search
- `GREATER_THAN` / `LOWER_THAN` - Numeric comparison

💡 **Tip**: Use with Context tab to understand why campaigns are/aren't showing

#### Allocations Tab
Shows traffic distribution:
- Percentage allocated to each variation
- Whether you're in the unallocated portion

### Resetting Forced States

**Per-campaign reset**:
- Tap **"Initial state"** on specific campaign
- Only that campaign reverts to natural state

**Global reset**:
- Tap **"Reset All"** button (top of Campaigns tab)
- All campaigns revert to natural state

**Automatic reset**:
- QA mode disabled
- App restarted

## Events Tab
Monitor all SDK events in real-time.

Events shown with icons: 📄 Page, 📱 Screen, 🎯 Event, 📊 Campaign. Search bar at top, Clear button to remove all events.
Viewing Event Details
Tap any event to view type, timestamp, action, category, label, and properties
When to Clear Events:
Starting a new test scenario
Isolating specific event sequences

## Context Tab
View current visitor information and context attributes.

Visitor ID and context attributes in JSON format
Why Context Matters
Targeting: Context values determine campaign eligibility
Personalization: Affects which variations you see
Testing: Change context to test different scenarios
Tip: Use Context tab with Targeting tab to understand campaign acceptance/rejection.

## Glossary
Accepted Campaign: A campaign the visitor is naturally allocated to. Active for the current visitor.
Rejected Campaign: A campaign the visitor is NOT allocated to due to targeting rules or traffic allocation.
Forced Allocation: Manual override enabling variation forcing for rejected campaigns. Campaign stays in Rejected section but badge changes to "Forced" (yellow), allowing you to force variations. Session-only - resets on app restart.
Forced Variation: Manual override switching to a specific variation within an accepted campaign or forced campaign. Session-only - resets on app restart.
Hide Campaign: Manual override hiding an accepted campaign, allowing testing of exclusion scenarios. Session-only - resets on app restart.
QA Mode: Special SDK mode enabling the QA Assistant interface.

## 6. Troubleshooting

### QA Assistant Not Appearing

**Problem**: Floating button doesn't show up

**Solutions**:
1. ✅ Verify QA mode is enabled in SDK configuration
2. ✅ Check SDK version (requires v2.0.0+)
3. ✅ Restart the app
4. ✅ Check console logs for initialization errors

### Campaigns Not Loading

**Problem**: Campaigns tab is empty or shows error

**Solutions**:
1. ✅ Verify internet connection
2. ✅ Check environment ID is correct
3. ✅ Ensure SDK is initialized before opening QA Assistant
4. ✅ Check console for API errors

### Forced Variations Not Applying

**Problem**: App still shows original variation after forcing

**Solutions**:
1. ✅ Close QA Assistant modal after forcing (changes apply on close)
2. ✅ Verify you forced the correct campaign/variation
3. ✅ Check if campaign was Accepted or Forced before forcing variation
4. ✅ Restart app and try again

### Events Not Appearing

**Problem**: Events tab doesn't show expected events

**Solutions**:
1. ✅ Ensure events are being sent (check your code)
2. ✅ Wait a few seconds for events to appear
3. ✅ Tap "Clear" and trigger events again
4. ✅ Check console for SDK errors

### Context Values Not Updating

**Problem**: Context tab shows outdated values

**Solutions**:
1. ✅ Close and reopen QA Assistant to refresh
2. ✅ Verify `updateContext()` is being called in your code
3. ✅ Check console logs for context update confirmations

### Need Help?

If issues persist:
- 📧 Contact support: [support@abtasty.com](mailto:support@abtasty.com)
- 📚 Check SDK documentation: [docs.developers.flagship.io](https://docs.developers.flagship.io)
- 🐛 Report bugs: [GitHub Issues](https://github.com/flagship-io/flagship-flutter-sdk/issues)

## 7. Best Practices

### Testing Workflow

1. **Start Clean**: Tap "Reset All" before new test session
2. **Test One Thing**: Force one variation at a time when possible
3. **Document Results**: Note forced states for test reports
4. **Reset After**: Always reset to natural state after testing

### Team Collaboration

- 🚫 Don't force variations in production builds
- 📝 Document which variations you're testing
- 🔄 Reset states before handoff to another tester
- 💬 Communicate forced states to team members

### Performance Tips

- Clear events regularly to maintain performance
- Don't leave QA Assistant open during app navigation
- Reset forced states when done testing
- Disable QA mode in production builds

## 8. Glossary

**Accepted Campaign**: A campaign the visitor is naturally allocated to based on targeting rules and traffic allocation. Active for the current visitor.

**Rejected Campaign**: A campaign the visitor is NOT allocated to, either because targeting conditions aren't met or the visitor falls outside the traffic allocation percentage.

**Forced Allocation**: Manual override that enables a rejected campaign for testing. Campaign stays in Rejected section but badge changes to "Forced" (yellow), allowing you to force variations. Resets on app restart or when QA mode is disabled.

**Forced Variation**: Manual override that switches to a specific variation within an accepted or forced campaign. Only available for campaigns that are accepted or have forced allocation. Resets on app restart or when QA mode is disabled.

**Hidden Campaign**: Manual override that excludes an accepted campaign, allowing you to test app behavior without that feature. Resets on app restart or when QA mode is disabled.

**QA Mode**: Special SDK mode that enables the QA Assistant interface for testing campaigns and feature flags. Should only be enabled in development/staging environments.

**Natural Allocation**: The default campaign assignment based on targeting rules and traffic distribution, without any manual overrides.

**Visitor Context**: Key-value pairs that describe the current user (e.g., device type, location, user properties). Used for campaign targeting.

**Variation**: A specific version of a campaign with its own set of feature flag modifications. Each campaign can have multiple variations.

**Traffic Allocation**: The percentage of visitors assigned to each variation within a campaign.

## 9. Frequently Asked Questions

### General

**Q: Can I use QA Assistant in production?**
A: No, QA mode should only be enabled in development and staging environments. It's not intended for production use.

**Q: Are forced states shared across devices?**
A: No, forced variations and allocations are local to the device session. Each device maintains its own forced states.

**Q: Can multiple team members force different variations?**
A: Yes, but each person's forced states are independent. Forced states don't sync between devices.

**Q: What happens to real users if I force a variation?**
A: Nothing. Forced states only affect your local device. Real users see natural allocations.

### Campaigns

**Q: Why can't I force a variation on a rejected campaign?**
A: You must first "Force display" on the rejected campaign, which changes its badge to "Forced" (yellow). Then you can force variations.

**Q: What's the difference between "Reset" and "Initial state"?**
A: They're the same action. "Reset" appears on variations, "Initial state" appears on campaigns. Both revert to natural allocation.

**Q: Can I force multiple campaigns at once?**
A: Yes! Force as many campaigns/variations as needed before closing QA Assistant. All changes apply when you close the modal.

**Q: Do hidden campaigns send events?**
A: No, hidden campaigns behave as if they were rejected. No activation or exposure events are sent.

### Events

**Q: How long are events stored?**
A: Events are stored only for the current app session. They're cleared when you restart the app or tap "Clear".

**Q: Can I export events?**
A: Not currently. Events are for real-time monitoring only.

**Q: Why don't I see all my events?**
A: Events may be filtered by the search bar, or the app may have cleared them. Also ensure events are being sent correctly in your code.

### Context

**Q: How often does context update?**
A: Context updates in real-time when `updateContext()` is called. Close and reopen QA Assistant to see the latest values.

**Q: Can I modify context from QA Assistant?**
A: Not currently. Context can only be updated programmatically through the SDK.

**Q: Why doesn't changing context affect my campaigns?**
A: Campaign allocation happens at fetch time. Changing context requires re-fetching campaigns to re-evaluate targeting.
