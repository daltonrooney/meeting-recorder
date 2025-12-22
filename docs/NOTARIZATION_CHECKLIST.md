# Notarization Documentation Test Plan

## Purpose
This checklist verifies that the notarization documentation is complete, accurate, and covers all necessary aspects for users to successfully set up GitHub Secrets for automated notarization in CI/CD.

## Documentation Requirements Checklist

### 1. Prerequisites Section
- [ ] Explains what notarization is and why it's needed
- [ ] Lists required Apple Developer account type
- [ ] Mentions macOS distribution requirements
- [ ] Links to official Apple documentation

### 2. Apple ID App-Specific Password
- [ ] Explains what an app-specific password is
- [ ] Provides step-by-step instructions to generate password
- [ ] Includes screenshots or detailed navigation path
- [ ] Warns about password visibility (save immediately)
- [ ] Explains password cannot be viewed again after creation

### 3. Required GitHub Secrets
- [ ] Lists all three required secrets clearly:
  - APPLE_ID
  - TEAM_ID
  - APP_SPECIFIC_PASSWORD
- [ ] Explains what each secret is used for
- [ ] Provides format/example for each secret (without exposing real values)
- [ ] Shows where to find TEAM_ID in Apple Developer account

### 4. Adding Secrets to GitHub Repository
- [ ] Step-by-step instructions to access repository settings
- [ ] Navigation path to Secrets section
- [ ] Instructions for adding each secret
- [ ] Screenshots or detailed description of GitHub UI
- [ ] Explains difference between repository and organization secrets
- [ ] Mentions when to use environment-specific secrets

### 5. Security Best Practices
- [ ] Never commit secrets to repository
- [ ] Rotate app-specific passwords periodically
- [ ] Limit access to repository settings
- [ ] Use organization secrets for multiple repos when appropriate
- [ ] Revoke passwords if compromised
- [ ] Explains GitHub's secret masking in logs

### 6. CI/CD Integration
- [ ] Explains how secrets are used in GitHub Actions
- [ ] References existing workflow file (.github/workflows/ci.yml)
- [ ] Shows how notarization is triggered
- [ ] Explains conditional execution (only on main branch, etc.)
- [ ] Links to notarize.sh script documentation

### 7. Verification and Troubleshooting
- [ ] How to verify secrets are set correctly
- [ ] Common errors and solutions
- [ ] How to check notarization status
- [ ] What to do if notarization fails
- [ ] Links to Apple's notarization service status page

### 8. Additional Resources
- [ ] Links to Apple Developer documentation
- [ ] Links to GitHub Secrets documentation
- [ ] Links to project's scripts/README.md
- [ ] Links to troubleshooting section in main README

### 9. Document Structure
- [ ] Clear table of contents
- [ ] Logical section ordering
- [ ] Consistent formatting
- [ ] Code blocks properly formatted
- [ ] Links are valid and relevant

### 10. Accessibility and Clarity
- [ ] Uses clear, concise language
- [ ] Avoids jargon or explains technical terms
- [ ] Suitable for developers with varying experience levels
- [ ] Includes examples where helpful
- [ ] Warning callouts for critical steps

## Success Criteria

Documentation is considered complete when:
1. All checklist items are verified
2. A developer new to notarization can follow the guide without external help
3. All three secrets can be set up correctly
4. Security best practices are clearly communicated
5. Troubleshooting guidance is comprehensive

## Related Files

- `/tmp/olive-worktrees/issue-111/docs/NOTARIZATION.md` (to be created)
- `/tmp/olive-worktrees/issue-111/README.md` (Distribution section)
- `/tmp/olive-worktrees/issue-111/scripts/README.md` (notarize.sh section)
- `/tmp/olive-worktrees/issue-111/scripts/notarize.sh` (implementation)
- `/tmp/olive-worktrees/issue-111/.github/workflows/ci.yml` (CI/CD integration)
