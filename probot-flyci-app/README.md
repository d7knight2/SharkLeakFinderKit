# FlyCI Wingman Auto-Apply GitHub App

A GitHub App built with [Probot](https://probot.github.io) that automatically applies FlyCI Wingman suggested fixes to pull requests.

## Features

- 🤖 **Automatic Detection** - Detects FlyCI Wingman suggestions in PR comments
- 🔧 **Patch Application** - Extracts and applies unified diff patches automatically
- 💾 **Auto-Commit** - Commits and pushes changes back to the PR branch
- 🔄 **Workflow Re-trigger** - Automatically re-runs failed workflow jobs
- 🔒 **Secure** - Uses GitHub App authentication with private key

## How It Works

1. **Comment Detection**: The app listens for new comments on pull requests
2. **Wingman Identification**: Checks if the comment contains FlyCI Wingman suggestions
3. **Patch Extraction**: Parses the comment body to extract unified diff patches
4. **Repository Cloning**: Clones the repository and checks out the PR branch
5. **Patch Application**: Applies each patch using `git apply`
6. **Changes Commit**: Stages, commits, and pushes changes to the PR branch
7. **Workflow Re-run**: Triggers a re-run of failed workflow jobs
8. **Feedback**: Posts a comment on the PR with the results

## Setup Instructions

### Prerequisites

- Node.js 18.0.0 or higher
- npm or yarn
- A GitHub repository where you want to use this app

### Step 1: Create a GitHub App

1. Go to your GitHub organization or personal account settings
2. Navigate to "Developer settings" > "GitHub Apps" > "New GitHub App"
3. Fill in the basic information:
   - **GitHub App name**: `FlyCI Wingman Auto-Apply` (or your preferred name)
   - **Homepage URL**: Your repository URL or website
   - **Webhook URL**: Your server URL (see deployment section)
   - **Webhook secret**: Generate a random string and save it

4. Set permissions:
   - **Repository permissions**:
     - Contents: Read & write
     - Pull requests: Read & write
     - Actions: Read & write
     - Issues: Read-only
   - **Subscribe to events**:
     - Issue comment

5. Choose where the app can be installed:
   - Select "Only on this account" (or "Any account" if you want to share it)

6. Click "Create GitHub App"

7. After creation, note your **App ID**

8. Generate and download a **private key**:
   - Scroll down to "Private keys" section
   - Click "Generate a private key"
   - Save the downloaded `.pem` file securely

### Step 2: Install the App

1. In your GitHub App settings, click "Install App" in the left sidebar
2. Select the account/organization where you want to install it
3. Choose the repositories where the app should have access
4. Click "Install"

### Step 3: Configure the Application

1. Clone this repository or navigate to the `probot-flyci-app` directory

2. Install dependencies:
   ```bash
   npm install
   ```

3. Create a `.env` file from the example:
   ```bash
   cp .env.example .env
   ```

4. Edit the `.env` file with your GitHub App credentials:
   ```env
   APP_ID=your-app-id
   WEBHOOK_SECRET=your-webhook-secret
   PRIVATE_KEY_PATH=path/to/your-private-key.pem
   ```

   Alternatively, you can provide the private key directly:
   ```env
   PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----
   YOUR_PRIVATE_KEY_CONTENT_HERE
   -----END RSA PRIVATE KEY-----"
   ```

### Step 4: Run the Application

#### Local Development

For local development, you can use [smee.io](https://smee.io) to forward GitHub webhooks to your local machine:

1. Go to https://smee.io and click "Start a new channel"
2. Copy the webhook proxy URL
3. Add it to your `.env` file:
   ```env
   WEBHOOK_PROXY_URL=https://smee.io/your-unique-id
   ```
4. Update your GitHub App's webhook URL to use the smee.io URL

5. Start the app:
   ```bash
   npm run dev
   ```

#### Production Deployment

For production, you can deploy to various platforms:

**Heroku:**
```bash
heroku create
heroku config:set APP_ID=your-app-id
heroku config:set WEBHOOK_SECRET=your-webhook-secret
heroku config:set PRIVATE_KEY="$(cat path/to/private-key.pem)"
git push heroku main
```

**Vercel:**
```bash
vercel --prod
```

**Docker:**
```bash
docker build -t flyci-wingman-app .
docker run -p 3000:3000 \
  -e APP_ID=your-app-id \
  -e WEBHOOK_SECRET=your-webhook-secret \
  -e PRIVATE_KEY_PATH=/app/private-key.pem \
  -v /path/to/private-key.pem:/app/private-key.pem \
  flyci-wingman-app
```

**Traditional Server:**
```bash
npm start
```

Make sure your server is accessible from the internet and update your GitHub App's webhook URL accordingly.

### Step 5: Verify Installation

1. Create a test pull request in a repository where the app is installed
2. Add a comment that simulates a FlyCI Wingman suggestion with a diff patch:
   ````markdown
   FlyCI Wingman Suggested Fix:
   
   ```diff
   diff --git a/test.txt b/test.txt
   index 1234567..abcdefg 100644
   --- a/test.txt
   +++ b/test.txt
   @@ -1 +1 @@
   -Hello World
   +Hello FlyCI Wingman
   ```
   ````

3. The app should automatically:
   - Detect the comment
   - Extract and apply the patch
   - Commit and push the changes
   - Post a success comment on the PR

## Usage

Once installed and configured, the app works automatically:

1. **Wait for FlyCI Wingman**: When FlyCI Wingman posts a suggestion on your PR
2. **Automatic Processing**: The app detects the comment and processes it
3. **Patch Application**: Patches are automatically applied to your PR branch
4. **Verification**: Check the PR for the new commit and comment from the app

## Configuration

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `APP_ID` | Yes | Your GitHub App ID |
| `WEBHOOK_SECRET` | Recommended | Secret for validating webhook payloads |
| `PRIVATE_KEY_PATH` | Yes* | Path to your GitHub App's private key file |
| `PRIVATE_KEY` | Yes* | Alternatively, the private key content directly |
| `LOG_LEVEL` | No | Logging level (default: `info`) |
| `PORT` | No | Port to listen on (default: `3000`) |
| `WEBHOOK_PROXY_URL` | No | Webhook proxy URL for local development |

\* Either `PRIVATE_KEY_PATH` or `PRIVATE_KEY` must be provided

## How Patches Are Detected

The app looks for code blocks in comments that contain unified diff format:

- Code blocks with ` ```diff ` or ` ```patch `
- Content starting with `diff`, `---`, `+++`, `@@`, or `+`/`-`

Example:
````markdown
```diff
diff --git a/file.txt b/file.txt
--- a/file.txt
+++ b/file.txt
@@ -1,3 +1,3 @@
 line 1
-line 2 old
+line 2 new
 line 3
```
````

## Troubleshooting

### App Not Responding

1. Check that the app is running and accessible
2. Verify webhook URL in GitHub App settings
3. Check webhook delivery status in GitHub App settings
4. Review app logs for errors

### Patches Not Applying

1. Ensure patches are in unified diff format
2. Check that the PR branch is up to date
3. Verify there are no merge conflicts
4. Review the app's comment on the PR for specific error messages

### Authentication Issues

1. Verify `APP_ID` is correct
2. Check that the private key is valid and properly formatted
3. Ensure the app has necessary permissions
4. Verify the app is installed on the repository

### Logs

Enable debug logging by setting:
```env
LOG_LEVEL=debug
```

This will provide more detailed information about the app's operation.

## Security Considerations

1. **Private Key**: Never commit your private key to version control
2. **Webhook Secret**: Use a strong, random webhook secret
3. **Environment Variables**: Store sensitive data in environment variables
4. **Permissions**: Only grant the minimum required permissions
5. **Access Control**: Limit app installation to necessary repositories

## Development

### Running Tests

```bash
npm test
```

### Code Structure

- `app.js` - Main application logic
- `manifest.json` - GitHub App manifest
- `package.json` - Dependencies and scripts
- `.env.example` - Environment variable template

### Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Support

For issues and questions:

1. Check this README for common solutions
2. Review [Probot documentation](https://probot.github.io/docs/)
3. Open an issue in the repository
4. Contact the maintainers

## Resources

- [Probot Documentation](https://probot.github.io/docs/)
- [GitHub Apps Documentation](https://docs.github.com/en/developers/apps)
- [GitHub REST API](https://docs.github.com/en/rest)
- [FlyCI Wingman](https://github.com/fly-ci/wingman-action)
