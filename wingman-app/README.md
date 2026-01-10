# FlyCI Wingman Applier - GitHub App

A GitHub App built with [Probot](https://probot.github.io) that automatically detects FlyCI Wingman PR comments and applies suggested code fixes.

## Overview

This app monitors pull request comments for FlyCI Wingman suggestions containing unified diff patches. When detected, it automatically:

1. Extracts diff patches from the comment
2. Clones the PR branch
3. Applies the patches using `git apply`
4. Commits and pushes the changes
5. Comments on the PR with results

This eliminates manual copy-paste of fixes and speeds up the CI feedback loop.

## Features

- ✅ **Automatic Detection** - Identifies Wingman comments by user login or diff content
- ✅ **Smart Patch Extraction** - Parses multiple diff blocks from a single comment
- ✅ **Secure Authentication** - Uses GitHub App private key for repository access
- ✅ **Error Handling** - Gracefully handles patch application failures
- ✅ **Detailed Reporting** - Comments back with success/failure status
- ✅ **Clean Commits** - Creates well-formatted commit messages with co-author attribution

## Prerequisites

- Node.js 18 or higher
- A GitHub account with permissions to create GitHub Apps
- Access to the repository where you want to install the app

## Setup Instructions

### 1. Install Dependencies

```bash
cd wingman-app
npm install
```

### 2. Create a GitHub App

You can create a GitHub App using the provided manifest:

1. Navigate to your repository settings
2. Go to **Developer settings** > **GitHub Apps** > **New GitHub App**
3. Or use the manifest approach:
   - Click [New GitHub App from manifest](https://github.com/settings/apps/new?manifest=true)
   - Paste the contents of `manifest.json`
   - Click **Create GitHub App from manifest**

#### Manual App Configuration

If creating manually, configure these settings:

**App Permissions:**
- Repository permissions:
  - Contents: Read & Write
  - Issues: Write
  - Pull requests: Write
  - Actions: Write

**Subscribe to events:**
- Issue comment
- Pull request

**Webhook:**
- Active: ✓
- Webhook URL: Your app's public URL or smee.io channel (for development)
- Webhook secret: Generate a random secret

### 3. Configure Environment Variables

Copy the example environment file:

```bash
cp .env.example .env
```

Edit `.env` with your GitHub App details:

```env
APP_ID=123456
WEBHOOK_SECRET=your-webhook-secret
PRIVATE_KEY_PATH=private-key.pem
WEBHOOK_PROXY_URL=https://smee.io/your-channel (for development)
```

### 4. Download Private Key

1. From your GitHub App settings page
2. Scroll to **Private keys**
3. Click **Generate a private key**
4. Save the downloaded `.pem` file as `private-key.pem` in the `wingman-app` directory

**Important:** Never commit your private key to version control!

### 5. Set Up Webhook Proxy (Development Only)

For local development, use [smee.io](https://smee.io) to proxy webhooks:

```bash
# Install smee-client globally
npm install -g smee-client

# Start the proxy
smee --url https://smee.io/your-channel --path /api/github/webhooks --port 3000
```

Update your `.env` with the smee.io URL:

```env
WEBHOOK_PROXY_URL=https://smee.io/your-channel
```

## Running the App

### Development Mode

```bash
npm run dev
```

This uses `nodemon` to automatically restart on file changes.

### Production Mode

```bash
npm start
```

The app will start listening on port 3000 (or the port specified in `.env`).

## Deployment

### Deploy to Cloud Platform

You can deploy this app to various platforms:

#### Heroku

```bash
heroku create
git push heroku main
heroku config:set APP_ID=your-app-id
heroku config:set WEBHOOK_SECRET=your-webhook-secret
heroku config:set PRIVATE_KEY="$(cat private-key.pem)"
```

#### Vercel

```bash
vercel deploy
```

Add environment variables in Vercel dashboard.

#### AWS Lambda / Google Cloud Functions

Use appropriate deployment tools and set environment variables in the cloud console.

### Environment Variables for Production

Ensure these are set in your production environment:

- `APP_ID`
- `WEBHOOK_SECRET`
- `PRIVATE_KEY` (or `PRIVATE_KEY_PATH` if using file system)
- `NODE_ENV=production`

## Installing the App

1. Go to your GitHub App's page
2. Click **Install App**
3. Select the repositories where you want to use the app
4. Approve the permissions

The app will now monitor those repositories for Wingman comments.

## How It Works

### 1. Comment Detection

The app listens for `issue_comment.created` events on pull requests.

It identifies Wingman comments by checking:
- Comment author login contains "wingman" or "fly-ci"
- Comment body contains diff blocks (` ```diff `)

### 2. Patch Extraction

Extracts all diff blocks from the comment:

```javascript
```diff
--- a/file.js
+++ b/file.js
@@ -1,3 +1,3 @@
-const x = 1;
+const x = 2;
```
```

### 3. Repository Cloning

- Creates a temporary working directory
- Uses installation token for authentication
- Clones the repository
- Checks out the PR branch

### 4. Patch Application

For each extracted patch:
- Writes patch to temporary file
- Runs `git apply --whitespace=fix`
- Tracks success/failure
- Attempts partial application with `--reject` if needed

### 5. Commit & Push

If changes were applied:
- Stages all changes with `git add`
- Creates commit with descriptive message
- Pushes to PR branch
- CI automatically re-runs

### 6. Reporting

Comments on the PR with results:
- Number of patches applied
- Number of patches that failed
- Whether changes were committed

## Usage Example

When FlyCI Wingman comments on a PR with suggested fixes:

```markdown
Here are some suggested fixes:

```diff
--- a/src/app.js
+++ b/src/app.js
@@ -10,7 +10,7 @@
-  const result = data.map(x => x * 2)
+  const result = data.map(x => x * 2);
```
```

The app will:
1. Detect the comment
2. Extract the diff
3. Apply the fix (adding semicolon)
4. Commit and push
5. Reply: "✅ FlyCI Wingman Fixes Applied - Successfully applied 1 patch(es)"

## Authentication

The app uses GitHub App authentication with a private key:

1. **Installation Access Token** - Short-lived token for repository access
2. **Private Key** - Used to generate installation tokens
3. **Webhook Secret** - Verifies webhook payload authenticity

### Security Best Practices

- ✅ Keep private key secure (never commit it)
- ✅ Use webhook secret to validate payloads
- ✅ Use minimum required permissions
- ✅ Rotate keys periodically
- ✅ Use environment variables for sensitive data

## Troubleshooting

### App Not Responding to Comments

1. Check webhook deliveries in GitHub App settings
2. Verify webhook secret matches `.env`
3. Check app logs for errors
4. Ensure app is running and accessible

### Patches Not Applying

1. Check that patches are valid unified diff format
2. Verify PR branch is up to date
3. Check for conflicts in target files
4. Review app logs for `git apply` errors

### Authentication Errors

1. Verify `APP_ID` is correct
2. Check private key is valid and readable
3. Ensure app is installed on the repository
4. Verify app has required permissions

### Webhook Delivery Issues

For development:
- Ensure smee proxy is running
- Check `WEBHOOK_PROXY_URL` is correct
- Verify port 3000 is accessible

For production:
- Ensure webhook URL is publicly accessible
- Check SSL certificate is valid
- Verify firewall/security group settings

## Testing

Run tests:

```bash
npm test
```

Watch mode:

```bash
npm run test:watch
```

## Contributing

Contributions are welcome! To contribute:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

MIT License - See LICENSE file for details

## Support

For issues or questions:
- Open an issue on GitHub
- Check Probot documentation: https://probot.github.io
- Review GitHub Apps documentation: https://docs.github.com/apps

## Additional Resources

- [Probot Documentation](https://probot.github.io)
- [GitHub Apps Documentation](https://docs.github.com/apps)
- [GitHub REST API](https://docs.github.com/rest)
- [Git Apply Documentation](https://git-scm.com/docs/git-apply)
- [FlyCI Wingman](https://fly-ci.com/wingman)

## Architecture

```
┌─────────────────┐
│  GitHub Event   │
│ (issue_comment) │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Probot App    │
│   (index.js)    │
└────────┬────────┘
         │
         ├─► Extract Patches
         │
         ├─► Clone Repository
         │
         ├─► Apply Patches
         │
         ├─► Commit & Push
         │
         └─► Comment Results
```

## Performance Considerations

- Uses temporary directories that are cleaned up after processing
- Clones repositories on-demand (not persistent)
- Processes patches sequentially for safety
- Includes timeout handling for long-running operations

## Future Enhancements

- [ ] Support for multiple PR comments in parallel
- [ ] Intelligent conflict resolution
- [ ] Dry-run mode for preview
- [ ] Patch validation before application
- [ ] Integration with CI status checks
- [ ] Dashboard for monitoring application success rates
