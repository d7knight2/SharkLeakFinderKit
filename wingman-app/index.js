/**
 * FlyCI Wingman Applier - GitHub App
 * 
 * This app automatically detects FlyCI Wingman PR comments containing
 * suggested fixes and applies them to the PR branch.
 * 
 * @param {import('probot').Probot} app
 */

const simpleGit = require('simple-git');
const fs = require('fs').promises;
const path = require('path');
const os = require('os');

module.exports = (app) => {
  app.log.info('FlyCI Wingman Applier app loaded!');

  // Listen for issue comments (includes PR comments)
  app.on('issue_comment.created', async (context) => {
    const { issue, comment, repository } = context.payload;
    
    // Only process comments on pull requests
    if (!issue.pull_request) {
      app.log.info('Comment is not on a pull request, skipping');
      return;
    }

    // Check if comment is from Wingman or contains diff patches
    const commentBody = comment.body;
    const isWingmanComment = 
      comment.user.login.toLowerCase().includes('wingman') ||
      comment.user.login.toLowerCase().includes('fly-ci') ||
      commentBody.includes('```diff');

    if (!isWingmanComment) {
      app.log.info('Comment does not appear to be from Wingman, skipping');
      return;
    }

    app.log.info(`Processing Wingman comment on PR #${issue.number}`);

    try {
      // Get PR details
      const pr = await context.octokit.pulls.get({
        owner: repository.owner.login,
        repo: repository.name,
        pull_number: issue.number
      });

      // Extract diff patches from comment
      const patches = extractDiffPatches(commentBody);
      
      if (patches.length === 0) {
        app.log.warn('No diff patches found in comment');
        await context.octokit.issues.createComment({
          owner: repository.owner.login,
          repo: repository.name,
          issue_number: issue.number,
          body: '⚠️ No valid diff patches found in the Wingman comment.'
        });
        return;
      }

      app.log.info(`Found ${patches.length} patch(es) to apply`);

      // Clone the repository and apply patches
      const result = await applyPatchesToPR(
        context,
        pr.data,
        patches,
        repository
      );

      // Report results
      await reportResults(context, issue.number, repository, result);

    } catch (error) {
      app.log.error('Error processing Wingman comment:', error);
      
      await context.octokit.issues.createComment({
        owner: repository.owner.login,
        repo: repository.name,
        issue_number: issue.number,
        body: `❌ Error applying Wingman fixes: ${error.message}`
      });
    }
  });

  /**
   * Extract diff patches from comment body
   * @param {string} commentBody - The comment body text
   * @returns {string[]} Array of patch strings
   */
  function extractDiffPatches(commentBody) {
    const patches = [];
    const lines = commentBody.split('\n');
    let inDiffBlock = false;
    let currentPatch = [];

    for (const line of lines) {
      if (line.trim().startsWith('```diff')) {
        inDiffBlock = true;
        currentPatch = [];
      } else if (line.trim() === '```' && inDiffBlock) {
        inDiffBlock = false;
        if (currentPatch.length > 0) {
          patches.push(currentPatch.join('\n'));
        }
      } else if (inDiffBlock) {
        currentPatch.push(line);
      }
    }

    return patches;
  }

  /**
   * Apply patches to PR branch
   * @param {import('probot').Context} context - Probot context
   * @param {object} pr - Pull request data
   * @param {string[]} patches - Array of patch strings
   * @param {object} repository - Repository data
   * @returns {Promise<object>} Result object with applied/failed counts
   */
  async function applyPatchesToPR(context, pr, patches, repository) {
    const workDir = await fs.mkdtemp(path.join(os.tmpdir(), 'wingman-'));
    app.log.info(`Working directory: ${workDir}`);

    try {
      // Get installation token for authentication
      const { token } = await context.octokit.apps.createInstallationAccessToken({
        installation_id: context.payload.installation.id
      });

      const repoUrl = `https://x-access-token:${token.data.token}@github.com/${repository.owner.login}/${repository.name}.git`;
      const git = simpleGit(workDir);

      // Clone the repository
      app.log.info(`Cloning repository: ${repository.full_name}`);
      await git.clone(repoUrl, workDir);
      await git.cwd(workDir);

      // Configure git
      await git.addConfig('user.name', 'flyci-wingman-applier[bot]');
      await git.addConfig('user.email', 'flyci-wingman-applier[bot]@users.noreply.github.com');

      // Checkout PR branch
      app.log.info(`Checking out branch: ${pr.head.ref}`);
      await git.checkout(pr.head.ref);

      let patchesApplied = 0;
      let patchesFailed = 0;

      // Apply each patch
      for (let i = 0; i < patches.length; i++) {
        const patchFile = path.join(workDir, `patch_${i}.patch`);
        await fs.writeFile(patchFile, patches[i]);

        try {
          app.log.info(`Applying patch ${i + 1}/${patches.length}`);
          await git.raw(['apply', '--whitespace=fix', patchFile]);
          patchesApplied++;
          app.log.info(`✅ Patch ${i + 1} applied successfully`);
        } catch (error) {
          app.log.warn(`⚠️ Patch ${i + 1} failed: ${error.message}`);
          patchesFailed++;
          
          // Try with --reject for partial application
          try {
            await git.raw(['apply', '--reject', '--whitespace=fix', patchFile]);
            app.log.info(`Patch ${i + 1} partially applied`);
          } catch (rejectError) {
            app.log.error(`Patch ${i + 1} completely failed`);
          }
        }
      }

      // Check if there are changes to commit
      const status = await git.status();
      
      if (status.files.length > 0) {
        app.log.info(`Committing changes (${status.files.length} file(s) modified)`);
        
        await git.add('.');
        await git.commit(
          `Apply FlyCI Wingman suggested fixes\n\nApplied ${patchesApplied} patch(es) from Wingman\n\nCo-authored-by: flyci-wingman-applier[bot] <flyci-wingman-applier[bot]@users.noreply.github.com>`
        );
        
        // Push changes
        app.log.info(`Pushing changes to ${pr.head.ref}`);
        await git.push('origin', pr.head.ref);
        
        app.log.info('✅ Changes pushed successfully');
      } else {
        app.log.info('No changes to commit');
      }

      return {
        patchesApplied,
        patchesFailed,
        hasChanges: status.files.length > 0
      };

    } finally {
      // Clean up temporary directory
      try {
        await fs.rm(workDir, { recursive: true, force: true });
        app.log.info('Cleaned up working directory');
      } catch (cleanupError) {
        app.log.warn('Failed to cleanup working directory:', cleanupError);
      }
    }
  }

  /**
   * Report results back to the PR
   * @param {import('probot').Context} context - Probot context
   * @param {number} issueNumber - Issue/PR number
   * @param {object} repository - Repository data
   * @param {object} result - Result from applying patches
   */
  async function reportResults(context, issueNumber, repository, result) {
    const { patchesApplied, patchesFailed, hasChanges } = result;

    let message = '';
    
    if (hasChanges) {
      message = `### ✅ FlyCI Wingman Fixes Applied\n\n`;
      message += `Successfully applied **${patchesApplied}** patch(es) from Wingman suggestions.\n\n`;
      
      if (patchesFailed > 0) {
        message += `⚠️ **${patchesFailed}** patch(es) could not be applied automatically.\n\n`;
      }
      
      message += `The changes have been committed and pushed. CI will re-run automatically.`;
    } else {
      message = `### ℹ️ No Changes Required\n\n`;
      message += `Processed ${patchesApplied + patchesFailed} patch(es) but no changes were needed.`;
    }

    await context.octokit.issues.createComment({
      owner: repository.owner.login,
      repo: repository.name,
      issue_number: issueNumber,
      body: message
    });
  }
};
