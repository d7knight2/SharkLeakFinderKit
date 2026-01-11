/**
 * FlyCI Wingman Auto-Apply GitHub App
 * 
 * This Probot app automatically detects FlyCI Wingman suggestions in PR comments,
 * extracts unified diff patches, applies them to the PR branch, commits and pushes
 * the changes, and triggers a workflow re-run.
 */

const simpleGit = require('simple-git');
const fs = require('fs').promises;
const path = require('path');
const os = require('os');

module.exports = (app) => {
  app.log.info('FlyCI Wingman Auto-Apply app loaded!');

  // Listen for new comments on issues (which includes PR comments)
  app.on('issue_comment.created', async (context) => {
    const { issue, comment, repository } = context.payload;
    
    // Only process comments on pull requests
    if (!issue.pull_request) {
      app.log.info('Comment is not on a PR, skipping');
      return;
    }

    // Check if comment is from FlyCI Wingman
    const commentBody = comment.body;
    const isFlyciWingman = 
      commentBody.includes('fly-ci/wingman') || 
      commentBody.includes('FlyCI Wingman') ||
      commentBody.includes('Suggested Fix');

    if (!isFlyciWingman) {
      app.log.info('Comment is not from FlyCI Wingman, skipping');
      return;
    }

    app.log.info(`Processing FlyCI Wingman comment on PR #${issue.number}`);

    try {
      // Get PR details
      const pr = await context.octokit.pulls.get({
        owner: repository.owner.login,
        repo: repository.name,
        pull_number: issue.number,
      });

      const prBranch = pr.data.head.ref;
      const prHeadSha = pr.data.head.sha;
      const repoUrl = pr.data.head.repo.clone_url;

      app.log.info(`PR Branch: ${prBranch}, HEAD SHA: ${prHeadSha}`);

      // Create temporary directory for cloning
      const tempDir = await fs.mkdtemp(path.join(os.tmpdir(), 'flyci-app-'));
      app.log.info(`Created temp directory: ${tempDir}`);

      try {
        // Initialize git
        const git = simpleGit(tempDir);

        // Configure git
        await git.addConfig('user.name', 'FlyCI Wingman Bot');
        await git.addConfig('user.email', 'flyci-bot@users.noreply.github.com');

        // Get installation token for authentication
        const installationId = context.payload.installation.id;
        const { data: { token } } = await context.octokit.apps.createInstallationAccessToken({
          installation_id: installationId,
        });

        // Clone the repository and checkout the PR branch
        const authenticatedUrl = repoUrl.replace(
          'https://',
          `https://x-access-token:${token}@`
        );

        app.log.info(`Cloning repository and checking out branch ${prBranch}`);
        await git.clone(authenticatedUrl, tempDir);
        await git.checkout(prBranch);

        // Extract patches from comment
        const patches = extractPatches(commentBody);
        
        if (patches.length === 0) {
          app.log.info('No patches found in comment');
          await addCommentToPR(context, issue.number, {
            success: false,
            message: 'No applicable patches found in the comment.',
          });
          return;
        }

        app.log.info(`Found ${patches.length} patch(es) to apply`);

        // Apply patches
        const results = await applyPatches(git, tempDir, patches, app);

        if (results.applied > 0) {
          // Check if there are changes to commit
          const status = await git.status();
          
          if (status.files.length === 0) {
            app.log.info('No changes to commit after applying patches');
            await addCommentToPR(context, issue.number, {
              success: false,
              message: 'Patches were applied but resulted in no changes.',
            });
            return;
          }

          // Stage all changes
          await git.add('-A');

          // Commit changes
          const commitMessage = `Apply FlyCI Wingman suggested fixes

Automatically applied fixes suggested by FlyCI Wingman.
Patches applied: ${results.applied}
Patches failed: ${results.failed}

Applied via FlyCI Wingman Auto-Apply GitHub App`;

          await git.commit(commitMessage);

          // Push changes
          app.log.info(`Pushing changes to branch ${prBranch}`);
          await git.push('origin', prBranch);

          app.log.info('Successfully pushed changes');

          // Trigger workflow re-run
          await triggerWorkflowRerun(context, repository, issue.number, app);

          // Add success comment to PR
          await addCommentToPR(context, issue.number, {
            success: true,
            applied: results.applied,
            failed: results.failed,
          });
        } else {
          app.log.info('No patches were successfully applied');
          await addCommentToPR(context, issue.number, {
            success: false,
            message: 'Failed to apply any patches. Manual intervention may be required.',
            failed: results.failed,
          });
        }
      } finally {
        // Clean up temporary directory
        try {
          await fs.rm(tempDir, { recursive: true, force: true });
          app.log.info('Cleaned up temp directory');
        } catch (err) {
          app.log.error('Failed to clean up temp directory:', err);
        }
      }
    } catch (error) {
      app.log.error('Error processing FlyCI Wingman comment:', error);
      
      try {
        await addCommentToPR(context, issue.number, {
          success: false,
          message: `Error applying fixes: ${error.message}`,
        });
      } catch (commentError) {
        app.log.error('Failed to add error comment:', commentError);
      }
    }
  });
};

/**
 * Extract unified diff patches from comment body
 */
function extractPatches(commentBody) {
  const patches = [];
  const lines = commentBody.split('\n');
  let currentPatch = [];
  let inCodeBlock = false;
  let isValidPatch = false;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];

    // Detect start of code block with diff/patch syntax
    if (line.match(/^```(diff|patch)/)) {
      inCodeBlock = true;
      currentPatch = [];
      isValidPatch = false;
      continue;
    }

    // Detect end of code block
    if (line.match(/^```$/) && inCodeBlock) {
      inCodeBlock = false;
      if (isValidPatch && currentPatch.length > 0) {
        patches.push(currentPatch.join('\n'));
      }
      currentPatch = [];
      continue;
    }

    // Collect patch lines
    if (inCodeBlock) {
      // Check if this is a valid unified diff line
      if (line.match(/^(diff |--- |\+\+\+ |@@ |[+-])/)) {
        isValidPatch = true;
      }
      currentPatch.push(line);
    }
  }

  return patches;
}

/**
 * Apply patches to the git repository
 */
async function applyPatches(git, repoPath, patches, app) {
  let applied = 0;
  let failed = 0;

  for (let i = 0; i < patches.length; i++) {
    const patch = patches[i];
    const patchFile = path.join(repoPath, `.flyci-patch-${i}.patch`);

    try {
      // Write patch to temporary file
      await fs.writeFile(patchFile, patch);

      // Try to apply the patch
      try {
        await git.raw(['apply', '--check', patchFile]);
        await git.raw(['apply', patchFile]);
        app.log.info(`Successfully applied patch ${i + 1}`);
        applied++;
      } catch (applyError) {
        app.log.error(`Failed to apply patch ${i + 1}:`, applyError.message);
        failed++;
      }

      // Clean up patch file
      try {
        await fs.unlink(patchFile);
      } catch (unlinkError) {
        app.log.warn('Failed to delete patch file:', unlinkError);
      }
    } catch (error) {
      app.log.error(`Error processing patch ${i + 1}:`, error);
      failed++;
    }
  }

  return { applied, failed };
}

/**
 * Trigger workflow re-run for failed jobs
 */
async function triggerWorkflowRerun(context, repository, prNumber, app) {
  try {
    // Get recent workflow runs for the repository
    const { data: workflowRuns } = await context.octokit.actions.listWorkflowRunsForRepo({
      owner: repository.owner.login,
      repo: repository.name,
      event: 'pull_request',
      status: 'failure',
      per_page: 10,
    });

    // Find workflow runs associated with this PR
    const prWorkflowRun = workflowRuns.workflow_runs.find(run => {
      return run.pull_requests && run.pull_requests.some(pr => pr.number === prNumber);
    });

    if (prWorkflowRun) {
      app.log.info(`Re-running workflow ${prWorkflowRun.id}`);
      
      await context.octokit.actions.reRunWorkflowFailedJobs({
        owner: repository.owner.login,
        repo: repository.name,
        run_id: prWorkflowRun.id,
      });

      app.log.info('Workflow re-run triggered successfully');
    } else {
      app.log.info('No failed workflow found for this PR');
    }
  } catch (error) {
    app.log.error('Error triggering workflow re-run:', error);
  }
}

/**
 * Add a comment to the PR with results
 */
async function addCommentToPR(context, prNumber, results) {
  let commentBody;

  if (results.success) {
    commentBody = `## 🤖 FlyCI Wingman Fixes Applied

✅ Successfully applied **${results.applied}** patch(es) from FlyCI Wingman suggestion.
`;

    if (results.failed > 0) {
      commentBody += `
⚠️ Failed to apply **${results.failed}** patch(es). These may need manual intervention.
`;
    }

    commentBody += `
📝 Changes have been committed and pushed to this branch.
🔄 Workflow will automatically re-run to verify the fixes.`;
  } else {
    commentBody = `## ⚠️ FlyCI Wingman Auto-Apply

${results.message}
`;

    if (results.failed > 0) {
      commentBody += `
Failed patches: **${results.failed}**
`;
    }

    commentBody += `
Please review the suggestions manually and apply them as needed.`;
  }

  app.log.debug(`Attempting to post a comment to PR #${prNumber} (length: ${commentBody.length} chars)`);
  
  try {
    await context.octokit.issues.createComment({
      owner: context.payload.repository.owner.login,
      repo: context.payload.repository.name,
      issue_number: prNumber,
      body: commentBody,
    });
    app.log.info(`Successfully posted comment to PR #${prNumber}`);
  } catch (error) {
    app.log.error(`Failed to post comment to PR #${prNumber}: ${error.message}`);
    throw error;
  }
}
