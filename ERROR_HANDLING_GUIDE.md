# Centralized Error Handling System

## Overview

We've implemented a centralized error handling system with **dialog-based error messages** for better user visibility and consistent UX across the entire app.

## Key Components

### 1. `ErrorHandler` (`lib/core/error/error_handler.dart`)
Centralized error handling with the following features:

#### Features:
- **Dialog-based error messages** for better visibility and user attention
- **Prevents duplicate error messages** within 2 seconds
- **Automatic session expiry handling** with proper logout flow
- **Multiple dialog types**: Error, Warning, Info, Confirmation
- **Snackbar for success** (less intrusive for positive feedback)
- **Global session dialog management** to prevent multiple dialogs

#### Usage:
```dart
// Handle any API error (shows error dialog)
await ErrorHandler.handleError(context, error);

// Show success message (snackbar - less intrusive)
ErrorHandler.showSuccess(context, 'Operation completed!');

// Show warning dialog
await ErrorHandler.showWarning(context, 'This action cannot be undone');

// Show info dialog
await ErrorHandler.showInfo(context, 'Feature will be available soon');

// Show confirmation dialog
final confirmed = await ErrorHandler.showConfirmation(
  context, 
  'Are you sure you want to delete this item?',
  isDangerous: true,
);
if (confirmed) {
  // User confirmed the action
}

// Clear error state (useful for testing)
ErrorHandler.clearErrorState();
```

### 2. `ApiService` (`lib/core/services/api_service.dart`)
Simplified API calling with built-in error handling.

#### Features:
- **Automatic error handling** for all HTTP methods
- **Success message extraction** from API responses
- **Loading state management** helper
- **Consistent response handling**

#### Usage:
```dart
// GET request
final data = await ApiService.get('/users', context: context);

// POST request with success message
final result = await ApiService.post(
  '/expenses',
  data: expenseData,
  context: context,
  showSuccessMessage: true,
);

// With loading state management
await ApiService.executeWithLoading(
  () => ApiService.post('/expenses', data: data, context: context),
  context: context,
  setLoading: (loading) => setState(() => _isLoading = loading),
);
```

## Benefits

### ✅ **Dialog vs Snackbar Strategy**

**🎯 Error Messages → Dialog:**
- Better visibility and user attention
- Cannot be missed or ignored
- User must acknowledge the error
- More professional appearance
- Suitable for critical error information

**✅ Success Messages → Snackbar:**
- Less intrusive for positive feedback
- Doesn't interrupt user workflow
- Auto-dismisses after 2 seconds
- Confirms action without blocking UI

### ✅ **Before vs After**

**❌ Before:**
```dart
// Multiple, inconsistent error handling
try {
  final response = await dio.post('/api');
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Success!')),
  );
} on DioException catch (e) {
  if (e.response?.statusCode == 401) {
    // Handle 401 manually
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error!')), // Easy to miss!
  );
} catch (e) {
  // More error handling
}
```

**✅ After:**
```dart
// Clean, centralized handling
final result = await ApiService.post('/api', context: context);
// Error dialog shown automatically - impossible to miss!
// Success snackbar for positive feedback
```

### Key Improvements:

1. **No Missed Errors**: Dialog format ensures users see error messages
2. **Professional UX**: Well-designed dialogs with icons and proper styling
3. **Balanced Feedback**: Dialogs for errors, snackbars for success
4. **No Duplicate Messages**: Prevents the same error dialog showing multiple times
5. **Session Management**: Automatically handles 401 errors with proper logout flow
6. **Confirmation Support**: Built-in confirmation dialogs for destructive actions

## Session Expiry Flow

When a 401 error occurs:
1. **Clear existing snackbars**
2. **Show session expired dialog** (only once, even if multiple APIs fail)
3. **User clicks "Login Again"**
4. **Automatic logout** and navigation to login screen
5. **No duplicate dialogs** or messages

## Error Message Hierarchy

1. **Custom message** (if provided)
2. **API response message** (`response.data.message`)
3. **Status code specific message** (400, 401, 500, etc.)
4. **Generic fallback message**

## Integration Guide

### For Existing Screens:
1. Replace direct API calls with `ApiService` methods
2. Remove manual error handling try-catch blocks  
3. Remove manual SnackBar calls
4. Import `ErrorHandler` for any custom error handling

### For New Screens:
1. Use `ApiService` for all API calls
2. Errors are handled automatically
3. Focus on business logic, not error handling

## Dialog Types & Usage Examples

### 🔴 **Error Dialog**
```dart
// Automatic via API calls
await ApiService.post('/expenses', data: data, context: context);

// Manual error dialog
await ErrorHandler.handleError(context, Exception('Custom error'));
```
**Appearance:** Red error icon, "Error" title, red OK button

### 🟠 **Warning Dialog**
```dart
await ErrorHandler.showWarning(
  context, 
  'This action cannot be undone',
  title: 'Warning', // Optional custom title
);
```
**Appearance:** Orange warning icon, "Warning" title, orange OK button

### 🔵 **Info Dialog**
```dart
await ErrorHandler.showInfo(
  context, 
  'Feature will be available in the next update',
  title: 'Coming Soon', // Optional custom title
);
```
**Appearance:** Blue info icon, "Information" title, black OK button

### ⚠️ **Confirmation Dialog**
```dart
final confirmed = await ErrorHandler.showConfirmation(
  context,
  'Are you sure you want to delete this expense?',
  title: 'Delete Expense',
  confirmText: 'Delete',
  cancelText: 'Cancel',
  isDangerous: true, // Makes it red for destructive actions
);

if (confirmed) {
  // User confirmed - proceed with deletion
  await ApiService.delete('/expenses/$id', context: context);
}
```
**Appearance:** Warning icon, custom title, Cancel + Confirm buttons

### ✅ **Success Snackbar**
```dart
// Automatic via API calls
await ApiService.post('/expenses', data: data, context: context);

// Manual success message
ErrorHandler.showSuccess(context, 'Expense added successfully!');
```
**Appearance:** Green snackbar with check icon, auto-dismisses

## Examples

### Simple API Call:
```dart
// Old way - easy to miss errors
try {
  final response = await ApiClient.instance.dio.post('/expenses', data: data);
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(...)); // Can be missed!
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(...)); // Can be missed!
}

// New way - impossible to miss errors
final result = await ApiService.post('/expenses', data: data, context: context);
if (result != null) {
  // Success! User saw success snackbar, any errors shown as prominent dialogs
}
```

### Delete Confirmation Flow:
```dart
// Ask for confirmation first
final confirmed = await ErrorHandler.showConfirmation(
  context,
  'Are you sure you want to delete this expense? This action cannot be undone.',
  title: 'Delete Expense',
  isDangerous: true,
);

if (confirmed) {
  // User confirmed, make API call
  final result = await ApiService.delete('/expenses/$id', context: context);
  if (result != null) {
    // Success snackbar shown automatically
    // Remove from local list or refresh data
  }
  // Error dialog shown automatically if something goes wrong
}
```

### With Loading State:
```dart
bool _isLoading = false;

await ApiService.executeWithLoading(
  () => ApiService.post('/expenses', data: data, context: context),
  context: context,
  setLoading: (loading) => setState(() => _isLoading = loading),
);
```

This system ensures **consistent, user-friendly error handling** across the entire application! 🎉
