# Appetize.io Upload Scripts

This directory contains scripts for uploading APK files to Appetize.io, along with testing utilities.

## Scripts

### 1. `upload-to-appetize.sh`

Main script for uploading APK files to Appetize.io.

**Usage:**
```bash
./scripts/upload-to-appetize.sh <apk_path> <appetize_token>
```

**Parameters:**
- `apk_path`: Path to the APK file to upload
- `appetize_token`: Your Appetize.io API token

**Features:**
- Validates APK file existence
- Displays file size information
- Uploads to Appetize.io API with proper authentication
- Provides detailed logging with colored output
- Extracts and displays app URL and key from response
- Proper error handling and exit codes

**Example:**
```bash
./scripts/upload-to-appetize.sh ./app/build/outputs/apk/release/app-release.apk YOUR_TOKEN_HERE
```

### 2. `test-appetize-upload.sh`

Mock testing script for validating upload functionality without making actual API calls.

**Usage:**
```bash
./scripts/test-appetize-upload.sh
```

**Test Coverage:**
1. APK Discovery - With APK present
2. APK Discovery - Without APK present
3. Mock Appetize.io API - Success Response
4. Mock Appetize.io API - Failure Response
5. Upload Script Validation
6. Environment Variable Validation
7. APK File Size Calculation
8. JSON Response Parsing

**Features:**
- Simulates APK discovery in various scenarios
- Mocks Appetize.io API responses (success and failure)
- Validates script existence and permissions
- Tests file size calculations
- Validates JSON parsing capabilities
- Comprehensive test reporting with pass/fail counts
- Color-coded output for easy reading

**Example:**
```bash
chmod +x ./scripts/test-appetize-upload.sh
./scripts/test-appetize-upload.sh
```

### 3. `unit-tests.sh`

Comprehensive unit tests for the upload and testing scripts using the bats-core testing framework pattern.

**Usage:**
```bash
./scripts/unit-tests.sh
```

**Test Coverage:**
- Script existence and permissions
- APK file discovery
- API response handling
- Error handling
- Integration with GitHub Actions

## GitHub Actions Workflow

The `.github/workflows/appetize-upload.yml` workflow automates APK uploads to Appetize.io.

**Triggers:**
- Push to `main` branch
- Manual trigger via workflow_dispatch

**Prerequisites:**
- Set `APPETIZE_TOKEN` secret in repository settings
- At least one APK file must exist in the repository

**Workflow Steps:**
1. Checkout repository
2. Find APK file (fails if none found)
3. Upload to Appetize.io
4. Log upload summary with app URL and key

## Setup Instructions

### 1. Make Scripts Executable

```bash
chmod +x scripts/*.sh
```

### 2. Set Up Appetize.io Token

1. Get your API token from [Appetize.io](https://appetize.io/)
2. Add it as a repository secret named `APPETIZE_TOKEN`:
   - Go to Settings > Secrets and variables > Actions
   - Click "New repository secret"
   - Name: `APPETIZE_TOKEN`
   - Value: Your Appetize.io API token

### 3. Run Tests

```bash
# Run mock tests
./scripts/test-appetize-upload.sh

# Run unit tests
./scripts/unit-tests.sh
```

### 4. Manual Upload

```bash
# Upload an APK manually
./scripts/upload-to-appetize.sh path/to/your/app.apk YOUR_APPETIZE_TOKEN
```

## Testing Recommendations

As mentioned in the requirements:

### JUnit Testing
For Java/Kotlin Android projects, you can validate APK discovery and upload functionality using JUnit:

```kotlin
@Test
fun testApkExists() {
    val apkFile = File("app/build/outputs/apk/release/app-release.apk")
    assertTrue(apkFile.exists())
}

@Test
fun testApkUploadScript() {
    val script = File("scripts/upload-to-appetize.sh")
    assertTrue(script.exists())
    assertTrue(script.canExecute())
}
```

### GitHub Actions Local Testing
Test the workflow using [act](https://github.com/nektos/act) before deploying:

```bash
# Install act
brew install act  # macOS
# or
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Run the workflow locally
act workflow_dispatch -W .github/workflows/appetize-upload.yml
```

## Troubleshooting

### No APK Found Error
- Ensure at least one `.apk` file exists in your repository
- Check that the APK is not in `.gitignore`
- APK files should be committed to the repository or built as part of the workflow

### Upload Failed Error
- Verify `APPETIZE_TOKEN` is set correctly in repository secrets
- Check that your Appetize.io account is active
- Ensure the APK file is valid and not corrupted

### Permission Denied
- Make scripts executable: `chmod +x scripts/*.sh`
- Check file permissions in your repository

## API Reference

### Appetize.io API Endpoint
- **URL:** `https://api.appetize.io/v1/apps`
- **Method:** POST
- **Authentication:** Basic Auth (token as username, no password)
- **Content-Type:** multipart/form-data

### Request Parameters
- `file`: APK file (binary)
- `platform`: "android"

### Response (Success - HTTP 200/201)
```json
{
  "publicKey": "app_key",
  "publicURL": "https://appetize.io/app/app_key",
  "privateKey": "private_key",
  "platform": "android",
  "created": "ISO_DATE",
  "updated": "ISO_DATE"
}
```

## Best Practices

1. **Security:** Never commit API tokens to the repository
2. **Testing:** Always run mock tests before actual uploads
3. **Validation:** Verify APK files before uploading
4. **Logging:** Monitor GitHub Actions logs for upload status
5. **Error Handling:** Handle API failures gracefully
6. **Modularity:** Keep scripts focused and single-purpose
7. **Documentation:** Document all changes and updates

## Contributing

When modifying these scripts:
1. Run all tests to ensure no regressions
2. Update documentation if adding new features
3. Follow existing code style and conventions
4. Add tests for new functionality

## License

These scripts are part of the SharkLeakFinderKit project and follow the same license.
