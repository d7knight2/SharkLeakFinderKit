# Intentional Compilation Errors

This document describes the deliberate compilation errors introduced to test the FlyCI Wingman automated failure analysis and fix suggestion workflows.

## Purpose
These errors are designed to:
1. Trigger CI build failures
2. Test Wingman's ability to analyze and suggest fixes
3. Provide clear, identifiable error messages in CI logs

## Errors Introduced

### Error 1: Missing Import in MainActivity.kt
**File**: `app/src/main/java/com/example/sharkleakfinderkit/MainActivity.kt`

**Change**: Removed the import statement for `android.widget.TextView`

**Line**: ~6 (comment indicates removal)

**Expected Error**: 
```
Unresolved reference: TextView
```

**Fix**: Add back the import statement:
```kotlin
import android.widget.TextView
```

---

### Error 2: Undefined Method Call in LeakyActivity.kt
**File**: `app/src/main/java/com/example/sharkleakfinderkit/LeakyActivity.kt`

**Change**: Added a call to non-existent method `performNonExistentOperation()`

**Line**: ~55

**Expected Error**:
```
Unresolved reference: performNonExistentOperation
```

**Fix**: Remove the line:
```kotlin
this.performNonExistentOperation()
```

---

### Error 3: Non-existent Class Reference in LeakReporter.kt
**File**: `app/src/main/java/com/example/sharkleakfinderkit/utils/LeakReporter.kt`

**Change**: Added instantiation of non-existent class `NonExistentReportFormatter`

**Line**: ~131

**Expected Error**:
```
Unresolved reference: NonExistentReportFormatter
```

**Fix**: Remove the line:
```kotlin
val formatter = NonExistentReportFormatter()
```

---

## How to Revert

To revert all intentional errors and restore the project to a working state:

```bash
git revert HEAD
```

Or manually remove the lines marked with comments containing "DELIBERATELY" in the three files mentioned above.

## Testing Wingman

1. Push these changes to trigger CI
2. Wait for CI to fail
3. Observe Wingman's analysis of the failures
4. Review Wingman's suggested fixes
5. Apply fixes and verify CI passes

---

**Created**: 2026-01-11
**Branch**: copilot/simulate-ci-failure
**Purpose**: FlyCI Wingman testing
