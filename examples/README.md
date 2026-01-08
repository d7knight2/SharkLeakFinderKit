# Examples

This directory contains example code for testing and integrating the Appetize.io upload workflow.

## AppetizeUploadTest.java

A comprehensive JUnit test suite for validating APK discovery and Appetize.io upload functionality.

### Purpose

This JUnit test class demonstrates best practices for testing APK-related functionality as recommended in the project requirements. While SharkLeakFinderKit is a JavaScript project, this example is provided for teams that want to integrate the Appetize.io upload workflow into Android applications.

### Test Coverage

The test suite includes:

1. **APK File Validation**
   - File existence checks
   - Extension validation
   - Readability verification

2. **APK Discovery**
   - Subdirectory searching
   - Multiple APK detection
   - File system operations

3. **Script Validation**
   - Upload script existence
   - Test script existence
   - Unit test script existence
   - Script executability checks

4. **Workflow Validation**
   - GitHub Actions workflow existence
   - Required trigger configuration
   - Secret reference validation

5. **Documentation Validation**
   - Scripts directory structure
   - README existence
   - Testing documentation

### Usage

#### Prerequisites

Add JUnit to your project dependencies:

**Maven (pom.xml):**
```xml
<dependency>
    <groupId>junit</groupId>
    <artifactId>junit</artifactId>
    <version>4.13.2</version>
    <scope>test</scope>
</dependency>
```

**Gradle (build.gradle):**
```gradle
testImplementation 'junit:junit:4.13.2'
```

#### Running Tests

**Command Line:**
```bash
# With Maven
mvn test -Dtest=AppetizeUploadTest

# With Gradle
./gradlew test --tests AppetizeUploadTest

# Direct execution (if compiled)
java -cp .:junit-4.13.2.jar:hamcrest-core-1.3.jar org.junit.runner.JUnitCore com.sharkleakfinder.test.AppetizeUploadTest
```

**IDE:**
- Right-click on the test class
- Select "Run 'AppetizeUploadTest'"

### Integration with Android Projects

To integrate these tests into your Android project:

1. Copy `AppetizeUploadTest.java` to your test directory:
   ```
   app/src/test/java/com/yourapp/test/AppetizeUploadTest.java
   ```

2. Update the package name to match your project:
   ```java
   package com.yourapp.test;
   ```

3. Adjust file paths if your project structure differs:
   ```java
   private static final String SCRIPTS_DIR = "../scripts";
   ```

4. Run tests as part of your CI/CD pipeline:
   ```yaml
   - name: Run Appetize Upload Tests
     run: ./gradlew test --tests AppetizeUploadTest
   ```

### Expected Output

```
Running Appetize.io Upload Test Suite...
==========================================

Test Results:
Tests run: 10
Tests passed: 10
Tests failed: 0
Success: true
```

### Customization

You can extend the test suite with additional tests:

```java
/**
 * Test: Validate APK signing
 */
@Test
public void testApkIsSigned() {
    // Your test logic here
}

/**
 * Test: Validate APK version
 */
@Test
public void testApkVersion() {
    // Your test logic here
}
```

### Notes

- These tests are **examples** and may need adaptation for your specific project
- The tests validate the workflow setup, not the actual upload process
- For full integration testing, use the shell scripts in the `scripts/` directory
- Mock API responses are used to avoid actual uploads during testing

### Related Files

- **Upload Script:** `../scripts/upload-to-appetize.sh`
- **Mock Test Script:** `../scripts/test-appetize-upload.sh`
- **Unit Tests:** `../scripts/unit-tests.sh`
- **Workflow:** `../.github/workflows/appetize-upload.yml`
- **Documentation:** `../scripts/README.md`, `../TESTING.md`

### Contributing

When adding new tests:
1. Follow the existing naming convention
2. Include descriptive JavaDoc comments
3. Ensure tests are independent and can run in any order
4. Clean up any resources in the `@After` method
5. Update this README with new test descriptions

## Additional Examples

Additional integration examples can be added to this directory:

- **CI/CD Integration:** Examples for Jenkins, GitLab CI, etc.
- **Gradle Tasks:** Custom Gradle tasks for APK upload
- **Maven Plugins:** Maven plugin configurations
- **Script Wrappers:** Language-specific wrappers for the shell scripts

## Support

For questions or issues:
- Review the main project README
- Check the scripts README at `../scripts/README.md`
- Consult the testing guide at `../TESTING.md`
- Open an issue in the repository
