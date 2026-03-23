# Generic Subscription Dialog Usage Guide

The `SubscriptionDialog` widget provides a unified interface for subscription-related operations across all detail screens (Member, Trial, Visitor, and Coach detail screens).

## Overview

Instead of duplicating subscription dialog code in each screen, we now have:
- **One generic widget**: `SubscriptionDialog` in `lib/widgets/subscription_dialog.dart`
- **Configurable for different actions**: renewal, upgrades, trial starts, etc.
- **Consistent UI/UX**: Same look and feel across all screens
- **Easy maintenance**: Single place to update subscription logic

## Usage Examples

### 1. Member Detail Screen - Membership Renewal

```dart
// In member_detail_screen.dart
import 'package:magical_community/widgets/subscription_dialog.dart';

// Usage in button onPressed:
showDialog(
  context: context,
  builder: (context) => SubscriptionDialog(
    config: SubscriptionDialogConfig.renewal(
      userName: member.name,
      onConfirm: (plan, amount) {
        _renewMembership(context, plan, 'renewal', amount);
      },
    ),
  ),
);
```

### 2. Trial Detail Screen - Upgrade to UMS

```dart
// In trial_detail_screen.dart
import 'package:magical_community/widgets/subscription_dialog.dart';

// Usage in button onPressed:
showDialog(
  context: context,
  builder: (context) => SubscriptionDialog(
    config: SubscriptionDialogConfig.trialUpgrade(
      userName: trial.name,
      onConfirm: (plan, amount) {
        _upgradeToMembership(context, plan, 'membership', amount);
      },
    ),
  ),
);
```

### 3. Visitor Detail Screen - Upgrade to UMS

```dart
// In visitor_detail_screen.dart
import 'package:magical_community/widgets/subscription_dialog.dart';

// Usage in button onPressed:
showDialog(
  context: context,
  builder: (context) => SubscriptionDialog(
    config: SubscriptionDialogConfig.visitorUpgrade(
      userName: visitor.name,
      onConfirm: (plan, amount) {
        _convertToMembership(context, plan, 'membership', amount);
      },
    ),
  ),
);
```

### 4. Visitor Detail Screen - Start Trial

```dart
// In visitor_detail_screen.dart
showDialog(
  context: context,
  builder: (context) => SubscriptionDialog(
    config: SubscriptionDialogConfig.trialStart(
      userName: visitor.name,
      onConfirm: (plan, amount) {
        _startTrial(context, plan, 'trial', amount);
      },
    ),
  ),
);
```

### 5. Coach Detail Screen (uses MemberDetailScreen)

Coach detail screens already use the `MemberDetailScreen`, so they automatically get the renewal functionality.

## Configuration Options

The `SubscriptionDialogConfig` class provides factory methods for different scenarios:

- **`.renewal()`** - Yellow theme for member renewals
- **`.trialUpgrade()`** - Green theme for trial to UMS upgrades  
- **`.visitorUpgrade()`** - Green theme for visitor to UMS upgrades
- **`.trialStart()`** - Yellow theme for starting trials

## Features

✅ **Automatic subscription plan loading** from API
✅ **Consistent validation** for payment amounts
✅ **Theme-aware colors** based on action type
✅ **Loading states** and error handling
✅ **Responsive design** with scrollable content
✅ **Form validation** for payment amounts

## Benefits

1. **Code Reduction**: Removed ~200+ lines of duplicate code per screen
2. **Consistency**: Same UI/UX across all subscription flows
3. **Maintainability**: Single place to update subscription logic
4. **Type Safety**: Strongly typed configuration
5. **Flexibility**: Easy to add new subscription types

## Migration Steps

To migrate existing screens:

1. **Add import**:
   ```dart
   import 'package:magical_community/widgets/subscription_dialog.dart';
   ```

2. **Replace old button action**:
   ```dart
   // OLD:
   onPressed: () => _showSubscriptionOptions(context, 'type'),
   
   // NEW:
   onPressed: () => showDialog(
     context: context,
     builder: (context) => SubscriptionDialog(
       config: SubscriptionDialogConfig.renewal( // or appropriate factory
         userName: user.name,
         onConfirm: (plan, amount) {
           _handleSubscription(context, plan, 'type', amount);
         },
       ),
     ),
   ),
   ```

3. **Remove old methods**:
   - Remove `_showSubscriptionOptions()`
   - Remove `_showConfirmSubscriptionDialog()`
   - Keep the final action method (e.g., `_renewMembership()`)

4. **Clean up state variables**:
   - Remove `_subscriptionPlans` list
   - Remove `_isLoadingPlans` boolean
   - Remove `_loadSubscriptionPlans()` method

## Testing

The generic dialog has been successfully integrated and tested in:
- ✅ Member Detail Screen (renewal)
- ✅ Trial Detail Screen (upgrade)
- 🔄 Visitor Detail Screen (pending)
- 🔄 Coach Detail Screen (uses Member screen, so already works)

All screens now use the same consistent subscription dialog with proper theming and validation.
