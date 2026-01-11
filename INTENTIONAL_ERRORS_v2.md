# Intentional Compilation Errors v2 - FlyCI Wingman Testing

This document describes intentional compilation errors introduced into the SharkLeakFinderKit codebase for testing FlyCI Wingman's error detection and fix capabilities.

## Purpose
These errors are deliberately introduced to:
1. Verify FlyCI Wingman can detect compilation failures
2. Test FlyCI's ability to suggest appropriate fixes
3. Validate the CI/CD workflow's error handling mechanisms
4. Ensure automated workflows correctly trigger on compilation issues

## Intentional Errors Introduced

### Error #1: Non-Existent Import
**File:** `app/src/main/java/com/example/sharkleakfinderkit/MainActivity.kt`  
**Line:** ~9 (after existing imports)  
**Type:** Unresolved reference  

**Code:**
```kotlin
import com.fake.library.NonExistentClass
```

**Expected Output:**
```
Unresolved reference: com.fake.library
```

**Purpose:** Tests FlyCI Wingman's ability to detect and report import errors for non-existent libraries/packages.

**Expected Fix:** Remove the import statement or add the missing library dependency.

---

### Error #2: Call to Non-Existent Method
**File:** `app/src/main/java/com/example/sharkleakfinderkit/MainActivity.kt`  
**Line:** ~31 (in `onCreate` method)  
**Type:** Unresolved reference  

**Code:**
```kotlin
triggerFakeCrash()
```

**Expected Output:**
```
Unresolved reference: triggerFakeCrash
```

**Purpose:** Tests FlyCI Wingman's ability to detect calls to undefined methods/functions.

**Expected Fix:** Define the method `triggerFakeCrash()` or remove the call.

---

### Error #3: Return Type Mismatch
**File:** `app/src/main/java/com/example/sharkleakfinderkit/utils/LeakReporter.kt`  
**Line:** ~31-37 (in `logLeak` method signature)  
**Type:** Type mismatch / Return type incompatibility  

**Code:**
```kotlin
fun logLeak(
    leakType: String,
    description: String,
    retainedHeapBytes: Long = 0,
    retainedObjectCount: Int = 0,
    trace: String = ""
): String {
    // Method body doesn't return a String
```

**Expected Output:**
```
A 'return' expression required in a function with a block body ('{...}')
Type mismatch: inferred type is Unit but String was expected
```

**Purpose:** Tests FlyCI Wingman's ability to detect return type mismatches where:
- Method signature declares return type `String`
- Method body doesn't return any value (implicitly Unit)
- Callers expect the method to return Unit (no value)

**Expected Fix:** Change return type back to `Unit` (no return type) or add appropriate return statements throughout the method body.

---

### Error #4: Incompatible Function Parameters
**File:** `app/src/main/java/com/example/sharkleakfinderkit/utils/LeakReporter.kt`  
**Line:** ~130 (in `generateSummaryReport` method signature)  
**Type:** Parameter type mismatch  

**Code:**
```kotlin
fun generateSummaryReport(invalidParam: Int): String {
```

**Expected Output:**
```
No value passed for parameter 'invalidParam'
Type mismatch: required Int found nothing
```

**Purpose:** Tests FlyCI Wingman's ability to detect parameter signature changes that break existing callers. This method is called without arguments in tests but now requires an Int parameter.

**Expected Fix:** Remove the `invalidParam: Int` parameter to restore the original signature, or update all call sites to pass the required parameter.

---

### Error #5: Invalid Gradle Configuration
**File:** `app/build.gradle.kts`  
**Line:** ~38 (in `kotlinOptions` block)  
**Type:** Invalid compiler argument  

**Code:**
```kotlin
kotlinOptions {
    jvmTarget = "1.8"
    freeCompilerArgs = listOf("-Xinvalid-option-does-not-exist")
}
```

**Expected Output:**
```
Invalid argument: -Xinvalid-option-does-not-exist
Unknown compiler option: -Xinvalid-option-does-not-exist
```

**Purpose:** Tests FlyCI Wingman's ability to detect invalid Gradle/Kotlin compiler configuration options.

**Expected Fix:** Remove the invalid `freeCompilerArgs` line or replace with valid Kotlin compiler options (e.g., `-Xopt-in=kotlin.RequiresOptIn`).

---

## Testing Instructions

### Building the Project
To verify these errors are detected during compilation:

```bash
./gradlew build
```

Expected result: **BUILD FAILED** with compilation errors listed above.

### Individual Error Testing

1. **Test Import Error:**
   ```bash
   ./gradlew :app:compileDebugKotlin
   ```

2. **Test Method Call Error:**
   ```bash
   ./gradlew :app:compileDebugKotlin
   ```

3. **Test Type Errors:**
   ```bash
   ./gradlew :app:compileDebugKotlin
   ```

4. **Test Gradle Configuration:**
   ```bash
   ./gradlew :app:compileDebugKotlin --info
   ```

### Fixing the Errors

To restore the project to a working state:

1. Remove line `import com.fake.library.NonExistentClass` from `MainActivity.kt`
2. Remove line `triggerFakeCrash()` from `MainActivity.kt`
3. Change `logLeak` return type from `: String` to `: Unit` (or remove) in `LeakReporter.kt`
4. Change `generateSummaryReport(invalidParam: Int)` to `generateSummaryReport()` in `LeakReporter.kt`
5. Remove `freeCompilerArgs = listOf("-Xinvalid-option-does-not-exist")` from `app/build.gradle.kts`

## CI/CD Integration

These errors should trigger the following in FlyCI Wingman:
- ✅ Detection of compilation failure
- ✅ Identification of specific error locations
- ✅ Suggestions for fixes
- ✅ Creation of automated fix pull requests (if configured)
- ✅ Workflow notifications to developers

## Notes

- All errors include clear `// INTENTIONAL ERROR #N:` comments for easy identification
- These errors are for **testing purposes only** and should not remain in production code
- Each error is independent and can be fixed separately
- The errors represent common developer mistakes that FlyCI Wingman should detect

## Version History

- **v2.0** - Initial comprehensive error set for FlyCI Wingman testing (2026-01-11)
  - Added 5 distinct error types across code and configuration
  - Included unresolved references, type mismatches, and invalid Gradle settings
