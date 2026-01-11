# Intentional Compilation Errors v2

This document tracks intentional compilation errors introduced into the SharkLeakFinderKit project for testing FlyCI Wingman workflows and automated CI failure analysis.

## Purpose

These intentional errors are designed to:
- Test FlyCI Wingman's ability to analyze and suggest fixes for compilation failures
- Validate automated CI/CD workflows for handling build failures
- Demonstrate different types of compilation errors that can occur in Kotlin/Android projects
- Provide test cases for the auto-apply functionality

## Version 2 Error Details

### Error Type: Type Mismatch
**Location:** `app/src/main/java/com/example/sharkleakfinderkit/MainActivity.kt`

**Lines:** 16-19

**Code:**
```kotlin
// INTENTIONAL ERROR v2: Type mismatch for FlyCI Wingman testing
// This should cause a compilation error due to incompatible types
// Expected error: "Type mismatch: inferred type is String but Int was expected"
private val intentionalError: Int = "This is a String not an Int"
```

**Error Description:**
A type mismatch error where a String literal is assigned to a variable declared as Int type. This is a fundamental type incompatibility that the Kotlin compiler will reject.

**Expected Compiler Error Message:**
```
Type mismatch: inferred type is String but Int was expected
```

**Expected Compiler Behavior:**
- Compilation will fail at the Kotlin compilation stage
- The error will be reported for MainActivity.kt
- The build process will terminate before reaching DEX compilation

**Severity:** Critical - Prevents compilation

**Category:** Type System Error

### Resolution Strategy

**Correct Fix Options:**
1. Change the type to String: `private val intentionalError: String = "This is a String not an Int"`
2. Change the value to an Int: `private val intentionalError: Int = 42`
3. Remove the variable if it's not needed

**Recommended Fix:**
Remove the variable entirely as it's not used in the application logic and serves only as a test case.

## Testing Instructions

### To Verify the Error:

1. Attempt to build the project:
   ```bash
   ./gradlew assembleDebug
   ```

2. Expected result: Build should fail with type mismatch error

3. Check the error output:
   ```bash
   ./gradlew assembleDebug 2>&1 | grep -A 5 "Type mismatch"
   ```

### To Test FlyCI Wingman:

1. Push this change to a branch
2. Create a pull request
3. Wait for CI to fail
4. Verify FlyCI Wingman analyzes the failure
5. Check if Wingman suggests appropriate fixes
6. Test the auto-apply functionality if available

## Differences from Previous Intentional Errors

This v2 error is intentionally different from any previous intentional errors:

- **Type:** Uses type system incompatibility rather than syntax errors
- **Detectability:** More semantic than syntactic - requires type checking
- **Fix Complexity:** Simple to fix, but requires understanding of type systems
- **Error Category:** Type mismatch vs. potential previous syntax/missing semicolon errors

## Notes for FlyCI Wingman Testing

### Expected Wingman Behavior:
- Should identify the type mismatch in MainActivity.kt
- Should suggest one of the correct fix options above
- Should be able to generate a patch that resolves the compilation error
- Should provide clear explanation of the type system violation

### Test Scenarios:
1. **Basic Detection:** Can Wingman identify the compilation error?
2. **Root Cause Analysis:** Does Wingman correctly identify it as a type mismatch?
3. **Fix Suggestion:** Does Wingman suggest removing or fixing the variable?
4. **Auto-Apply:** Can Wingman automatically apply a fix that resolves the error?
5. **Verification:** After applying the fix, does the build succeed?

## Cleanup Instructions

To remove this intentional error and restore normal compilation:

1. Remove lines 16-19 from MainActivity.kt (the intentionalError variable and its comments)
2. Delete or archive this documentation file
3. Verify build succeeds:
   ```bash
   ./gradlew clean assembleDebug
   ```

## Related Documentation

- [FLYCI_WINGMAN_INTEGRATION.md](FLYCI_WINGMAN_INTEGRATION.md) - FlyCI Wingman setup and configuration
- [TESTING.md](TESTING.md) - General testing guidelines
- [README.md](README.md) - Project overview

## Metadata

- **Created:** 2026-01-11
- **Author:** FlyCI Wingman Testing Team
- **Version:** 2.0
- **Status:** Active
- **Related Issue:** Testing FlyCI Wingman workflows
