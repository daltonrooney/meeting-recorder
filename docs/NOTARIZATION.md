# macOS App Notarization with GitHub Secrets

This guide explains how to set up GitHub Secrets for automated notarization of the Olive macOS application in CI/CD pipelines.

## Table of Contents

- [What is Notarization?](#what-is-notarization)
- [Prerequisites](#prerequisites)
- [Creating an App-Specific Password](#creating-an-app-specific-password)
- [Required GitHub Secrets](#required-github-secrets)
- [Finding Your Team ID](#finding-your-team-id)
- [Adding Secrets to GitHub](#adding-secrets-to-github)
- [Security Best Practices](#security-best-practices)
- [CI/CD Integration](#cicd-integration)
- [Verification and Troubleshooting](#verification-and-troubleshooting)
- [Additional Resources](#additional-resources)

## What is Notarization?

**Notarization** is Apple's automated service that scans macOS software for malicious content and confirms the app is signed with a valid Developer ID certificate. When users download your app, macOS Gatekeeper checks for notarization and allows the app to run without security warnings.

**Why it's required:**
- Apps distributed outside the Mac App Store need notarization to avoid Gatekeeper warnings
- Users see "App is damaged" or "App cannot be opened" errors without notarization
- Required for apps running on macOS 10.15 (Catalina) and later

**When to use:**
- Distributing release builds to users
- Creating downloadable packages for GitHub releases
- Automated CI/CD deployment pipelines

**Note:** Notarization is **optional** for:
- Development builds
- Internal testing
- Apps distributed exclusively through the Mac App Store

## Prerequisites

Before setting up GitHub Secrets for notarization, you need:

1. **Apple Developer Account**
   - Paid Apple Developer Program membership ($99/year)
   - Free accounts cannot create Developer ID certificates needed for notarization
   - Enroll at: https://developer.apple.com/programs/

2. **Valid Developer ID Certificate**
   - Created in Apple Developer Account
   - Installed in Xcode or Keychain Access
   - Used to sign the app before notarization

3. **Code Signing Configuration**
   - App must be signed with Developer ID certificate
   - Hardened runtime must be enabled in Xcode build settings
   - Entitlements properly configured

4. **GitHub Repository Access**
   - Admin or write access to repository settings
   - Permission to add secrets

## Creating an App-Specific Password

App-specific passwords are unique passwords that grant access to your Apple ID for automated tools without exposing your primary Apple ID password.

### Step-by-Step Instructions

1. **Sign in to Apple ID Account Page**
   - Go to: https://appleid.apple.com/
   - Sign in with your Apple ID (the one associated with your Apple Developer account)

2. **Navigate to Security Section**
   - Click on "Sign-In and Security" in the sidebar
   - Or access directly: https://appleid.apple.com/account/manage

3. **Generate App-Specific Password**
   - Scroll to "App-Specific Passwords" section
   - Click "Generate an app-specific password..." or the "+" button
   - You may be prompted to answer security questions or verify with two-factor authentication

4. **Label the Password**
   - Enter a descriptive label (e.g., "GitHub Actions Notarization" or "Olive CI/CD")
   - This helps you identify the password later if you need to revoke it
   - Click "Create" or "Generate"

5. **Copy and Save the Password**
   - **CRITICAL:** The password is displayed **only once**
   - Copy it immediately and save it securely
   - Format: `xxxx-xxxx-xxxx-xxxx` (four groups of four characters)
   - You **cannot** view this password again after closing the window
   - If you lose it, you must revoke it and create a new one

6. **Store Securely**
   - Temporarily save in a password manager or secure note
   - You'll use this when adding GitHub Secrets (next section)
   - Never commit this password to git or share it publicly

### Revoking App-Specific Passwords

If a password is compromised or no longer needed:

1. Go to https://appleid.apple.com/
2. Navigate to "Sign-In and Security" → "App-Specific Passwords"
3. Click "View History..." or the list icon
4. Find the password by its label
5. Click "Revoke" or the "×" button next to it
6. Confirm revocation

**Note:** Revoking a password immediately invalidates it. Any CI/CD workflows using it will fail until you generate and configure a new password.

## Required GitHub Secrets

Three secrets are required for automated notarization in GitHub Actions:

### 1. APPLE_ID

**What it is:** Your Apple ID email address used for your Apple Developer account.

**Format:** `your.email@example.com`

**Example:**
```
developer@example.com
```

**Where to find it:**
- The email you use to sign in to https://developer.apple.com/
- Same as your Apple ID at https://appleid.apple.com/

**Important:**
- Must be the Apple ID associated with your Developer Program membership
- Must have valid Developer ID certificate
- Use the full email address (not just username)

---

### 2. TEAM_ID

**What it is:** Your Apple Developer Team ID, a unique 10-character identifier for your development team.

**Format:** `XXXXXXXXXX` (10 alphanumeric characters)

**Example:**
```
A1B2C3D4E5
```

**Where to find it:** See [Finding Your Team ID](#finding-your-team-id) section below.

**Important:**
- Case-sensitive (always uppercase)
- Exactly 10 characters
- Same for all apps under your Apple Developer account
- Different from Bundle Identifier or App ID

---

### 3. APP_SPECIFIC_PASSWORD

**What it is:** The app-specific password you generated in the previous section.

**Format:** `xxxx-xxxx-xxxx-xxxx` (16 characters in 4 groups)

**Example:**
```
abcd-efgh-ijkl-mnop
```

**Where to find it:** Created at https://appleid.apple.com/ (see [Creating an App-Specific Password](#creating-an-app-specific-password))

**Important:**
- Include hyphens exactly as shown when generated
- Valid only for automated tools (not for signing in to websites)
- Can be revoked and regenerated at any time
- Each password can be used for multiple repositories/workflows

## Finding Your Team ID

Your Team ID is available in multiple locations:

### Method 1: Apple Developer Website (Recommended)

1. Go to https://developer.apple.com/account
2. Sign in with your Apple ID
3. Click "Membership" or "Membership Details" in the sidebar
4. Your Team ID is listed under "Team ID" or "Membership Information"
5. Copy the 10-character alphanumeric code

### Method 2: Xcode

1. Open Xcode
2. Go to Xcode → Settings... (or Preferences on older versions)
3. Click the "Accounts" tab
4. Select your Apple ID from the list
5. Click "Manage Certificates..." or "View Details..."
6. Your Team ID appears next to your team name
7. If you have multiple teams, select the correct one

### Method 3: App Store Connect

1. Go to https://appstoreconnect.apple.com/
2. Sign in with your Apple ID
3. Click your name in the top-right corner
4. Select "View Membership Details"
5. Team ID is listed in the membership information

### Method 4: Terminal (macOS)

If you have a valid Developer ID certificate installed:

```bash
# List all code signing identities
security find-identity -v -p codesigning

# Look for "Developer ID Application: Your Name (TEAM_ID)"
# The Team ID is the 10-character code in parentheses
```

Example output:
```
1) A1B2C3D4E5F6G7H8I9J0 "Developer ID Application: John Doe (A1B2C3D4E5)"
                                                              ^^^^^^^^^^^
                                                              Your Team ID
```

## Adding Secrets to GitHub

Follow these steps to add the three required secrets to your GitHub repository:

### Step 1: Access Repository Settings

1. Navigate to your repository on GitHub (e.g., `https://github.com/username/olive-call-transcription`)
2. Click the "Settings" tab (requires admin or write access)
3. In the left sidebar, expand "Secrets and variables"
4. Click "Actions"

**Visual path:**
```
Repository → Settings → Secrets and variables → Actions
```

### Step 2: Add Each Secret

For each of the three secrets (APPLE_ID, TEAM_ID, APP_SPECIFIC_PASSWORD):

1. Click the "New repository secret" button (green button in top-right)

2. **Enter Secret Name**
   - Must be **exactly** as shown (case-sensitive):
     - `APPLE_ID`
     - `TEAM_ID`
     - `APP_SPECIFIC_PASSWORD`
   - GitHub will show an error if the name contains invalid characters

3. **Enter Secret Value**
   - Paste the corresponding value:
     - APPLE_ID: `your.email@example.com`
     - TEAM_ID: `A1B2C3D4E5`
     - APP_SPECIFIC_PASSWORD: `xxxx-xxxx-xxxx-xxxx`
   - Do not add quotes, spaces, or extra characters
   - Paste the exact value

4. **Add Secret**
   - Click "Add secret" button
   - The value will be masked (shown as `***`) once saved
   - You cannot view the value again (only update or delete)

5. **Repeat for Remaining Secrets**
   - Click "New repository secret" again
   - Add the next secret
   - Repeat until all three are added

### Step 3: Verify Secrets Are Set

After adding all three secrets:

1. You should see three secrets listed:
   - `APPLE_ID`
   - `APP_SPECIFIC_PASSWORD`
   - `TEAM_ID`

2. Each shows:
   - Secret name
   - Last updated timestamp
   - Options to "Update" or "Remove"

3. Values are always masked for security

**Screenshot equivalent:**
```
Repository secrets

Name                    Updated
APPLE_ID                2 minutes ago  [Update] [Remove]
APP_SPECIFIC_PASSWORD   1 minute ago   [Update] [Remove]
TEAM_ID                 3 minutes ago  [Update] [Remove]
```

## Security Best Practices

Follow these security practices when managing GitHub Secrets for notarization:

### 1. Never Commit Secrets to Repository

**❌ NEVER do this:**
```bash
# .env file (if committed)
APPLE_ID=developer@example.com
APP_SPECIFIC_PASSWORD=abcd-efgh-ijkl-mnop

# config.yml (if committed)
apple:
  id: developer@example.com
  password: abcd-efgh-ijkl-mnop
```

**✅ ALWAYS use GitHub Secrets:**
```yaml
# .github/workflows/ci.yml
- name: Notarize app
  env:
    APPLE_ID: ${{ secrets.APPLE_ID }}
    APP_SPECIFIC_PASSWORD: ${{ secrets.APP_SPECIFIC_PASSWORD }}
```

**Why:** Committed secrets are visible in git history forever, even if deleted later.

### 2. Rotate App-Specific Passwords Periodically

**Recommended schedule:**
- Every 90 days for active workflows
- Immediately if a team member with access leaves
- After any suspected security incident

**How to rotate:**
1. Generate new app-specific password at https://appleid.apple.com/
2. Update `APP_SPECIFIC_PASSWORD` secret in GitHub
3. Revoke old app-specific password
4. Test workflow to confirm new password works

### 3. Limit Repository Access

**Best practices:**
- Only give admin access to trusted maintainers
- Write access allows reading secret values in workflow runs
- Use organization secrets for multiple repositories (see below)
- Review repository collaborators regularly

**Check access:**
1. Repository → Settings → Collaborators and teams
2. Review who has admin/write access
3. Remove users who no longer need access

### 4. Use Organization Secrets for Multiple Repositories

If you manage multiple macOS apps under the same Apple Developer account:

**✅ Use organization-level secrets:**
1. Go to Organization → Settings → Secrets and variables → Actions
2. Add secrets at organization level
3. Select which repositories can access them
4. All selected repos share the same secrets

**Benefits:**
- Single source of truth for credentials
- Easier rotation (update once, applies everywhere)
- Centralized access control
- Reduced duplication

### 5. Monitor Workflow Runs for Exposed Secrets

GitHub automatically masks secret values in workflow logs:

**What you'll see in logs:**
```
Submitting to Apple for notarization...
Using Apple ID: ***
Using Team ID: ***
```

**If you see unmasked values:**
- Immediately revoke the app-specific password
- Rotate all affected secrets
- Review workflow code for accidental echo/print statements

### 6. Revoke Compromised Passwords Immediately

**If a secret is exposed:**
1. Go to https://appleid.apple.com/
2. Revoke the app-specific password (see [Revoking App-Specific Passwords](#revoking-app-specific-passwords))
3. Generate a new password
4. Update GitHub secret
5. Check git history to ensure password wasn't committed

**Compromised indicators:**
- Password visible in logs
- Unauthorized notarization requests
- Team member with access leaves without rotating secrets

### 7. Use Environment-Specific Secrets (Advanced)

For complex workflows with staging/production environments:

```yaml
# .github/workflows/ci.yml
jobs:
  notarize-production:
    environment: production  # Uses production-specific secrets
    steps:
      - name: Notarize
        env:
          APPLE_ID: ${{ secrets.APPLE_ID }}
```

**Setup:**
1. Repository → Settings → Environments
2. Create "production" environment
3. Add secrets scoped to that environment
4. Add protection rules (e.g., require manual approval)

## CI/CD Integration

The notarization secrets are used by GitHub Actions to automatically notarize release builds.

### Current Workflow

The Olive project uses GitHub Actions for continuous integration. Notarization is **optional** and only runs when secrets are configured.

**Workflow file:** `.github/workflows/ci.yml`

**When notarization runs:**
- Currently **NOT** automated in CI/CD (manual process)
- Can be triggered locally with `./scripts/notarize.sh Release`
- Secrets must be set as environment variables or GitHub Secrets

### Local Notarization

To notarize locally (without GitHub Actions):

```bash
# Set environment variables
export APPLE_ID="your@apple.id"
export TEAM_ID="YOUR_TEAM_ID"
export APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx"

# Build and notarize
./scripts/build.sh Release
./scripts/notarize.sh Release
```

**Script behavior:**
- Verifies app is signed with Developer ID certificate
- Creates ZIP archive of the app
- Submits to Apple's notarization service
- Waits for notarization to complete (can take 5-30 minutes)
- Staples notarization ticket to the app if successful
- Exits gracefully if secrets are not set (no error)

### Adding Automated Notarization to CI/CD (Future)

To enable automated notarization in GitHub Actions, add this job to `.github/workflows/ci.yml`:

```yaml
notarize:
  name: Notarize Release Build
  runs-on: macos-15
  needs: package
  if: github.event_name == 'push' && github.ref == 'refs/heads/main'

  steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Download package artifact
      uses: actions/download-artifact@v4
      with:
        name: olive-distribution

    - name: Extract package
      run: |
        unzip dist/Olive-*.zip -d build/Build/Products/Release/

    - name: Notarize app
      env:
        APPLE_ID: ${{ secrets.APPLE_ID }}
        TEAM_ID: ${{ secrets.TEAM_ID }}
        APP_SPECIFIC_PASSWORD: ${{ secrets.APP_SPECIFIC_PASSWORD }}
      run: |
        ./scripts/notarize.sh Release

    - name: Re-package notarized app
      run: |
        ./scripts/package.sh Release

    - name: Upload notarized package
      uses: actions/upload-artifact@v4
      with:
        name: olive-distribution-notarized
        path: dist/*.zip
```

**Key points:**
- Runs only on `main` branch pushes (not PRs)
- Requires secrets to be set (otherwise skips gracefully)
- Downloads build artifact from previous job
- Notarizes the app
- Uploads notarized version as new artifact

### Conditional Execution

The `scripts/notarize.sh` script automatically skips notarization if secrets are missing:

```bash
if [ -z "$APPLE_ID" ] || [ -z "$TEAM_ID" ] || [ -z "$APP_SPECIFIC_PASSWORD" ]; then
    echo "Notarization skipped: Missing required environment variables"
    exit 0  # Success, not failure
fi
```

**Benefits:**
- CI/CD works for forks and contributors without Apple Developer accounts
- No workflow errors if secrets aren't configured
- Optional feature that doesn't block development

## Verification and Troubleshooting

### Verifying Secrets Are Set Correctly

**1. Check GitHub Secrets Page**
- Repository → Settings → Secrets and variables → Actions
- Verify all three secrets are listed
- Names must match exactly (case-sensitive)

**2. Test in GitHub Actions (Dry Run)**

Add a temporary workflow step to verify secrets are accessible (without exposing values):

```yaml
- name: Verify secrets are set
  run: |
    if [ -z "${{ secrets.APPLE_ID }}" ]; then
      echo "❌ APPLE_ID is not set"
      exit 1
    fi
    if [ -z "${{ secrets.TEAM_ID }}" ]; then
      echo "❌ TEAM_ID is not set"
      exit 1
    fi
    if [ -z "${{ secrets.APP_SPECIFIC_PASSWORD }}" ]; then
      echo "❌ APP_SPECIFIC_PASSWORD is not set"
      exit 1
    fi
    echo "✅ All secrets are set"
```

**3. Test Locally**

Verify credentials work before committing to CI/CD:

```bash
export APPLE_ID="your@apple.id"
export TEAM_ID="YOUR_TEAM_ID"
export APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx"

# Test notarytool authentication
xcrun notarytool history \
  --apple-id "$APPLE_ID" \
  --team-id "$TEAM_ID" \
  --password "$APP_SPECIFIC_PASSWORD"
```

Expected output: List of previous notarization submissions (or empty if none)

### Common Errors and Solutions

#### Error: "Invalid credentials"

**Symptoms:**
```
Error: The request could not be authenticated with the credentials provided.
```

**Causes:**
- Wrong Apple ID
- Wrong app-specific password
- App-specific password revoked

**Solutions:**
1. Verify APPLE_ID matches your Apple Developer account email
2. Generate a new app-specific password
3. Update APP_SPECIFIC_PASSWORD secret in GitHub
4. Confirm two-factor authentication is enabled on your Apple ID

---

#### Error: "Invalid Team ID"

**Symptoms:**
```
Error: The specified Team ID is not valid.
```

**Causes:**
- Wrong Team ID format
- Team ID from different Apple ID
- Typo in Team ID

**Solutions:**
1. Verify Team ID is exactly 10 characters
2. Check Team ID at https://developer.apple.com/account
3. Ensure Team ID matches the Apple ID being used
4. Update TEAM_ID secret in GitHub (case-sensitive)

---

#### Error: "App is not signed"

**Symptoms:**
```
Error: The application is not signed with a Developer ID certificate.
```

**Causes:**
- App signed with wrong certificate
- App not signed at all
- Xcode code signing configuration incorrect

**Solutions:**
1. Verify code signing settings in Xcode:
   - Signing & Capabilities → Team → Select your team
   - Signing Certificate → Developer ID Application
2. Check certificate is installed:
   ```bash
   security find-identity -v -p codesigning
   ```
3. Rebuild app with correct signing:
   ```bash
   ./scripts/build.sh Release clean
   ```

---

#### Error: "Hardened runtime required"

**Symptoms:**
```
Warning: Hardened runtime not detected
```

**Causes:**
- Hardened Runtime not enabled in Xcode build settings

**Solutions:**
1. Open Xcode project
2. Select Olive target
3. Go to Signing & Capabilities tab
4. Click "+ Capability" button
5. Add "Hardened Runtime"
6. Rebuild app

---

#### Error: "Notarization failed - Invalid entitlements"

**Symptoms:**
```
Error: The executable does not have the required entitlements.
```

**Causes:**
- Missing or invalid entitlements for hardened runtime
- Entitlements file misconfigured

**Solutions:**
1. Check entitlements file (usually `Olive.entitlements`)
2. Ensure required entitlements for audio recording:
   ```xml
   <key>com.apple.security.device.audio-input</key>
   <true/>
   ```
3. Rebuild and re-notarize

---

### Checking Notarization Status

**View recent submissions:**
```bash
xcrun notarytool history \
  --apple-id "$APPLE_ID" \
  --team-id "$TEAM_ID" \
  --password "$APP_SPECIFIC_PASSWORD"
```

**Get details for specific submission:**
```bash
xcrun notarytool info <submission-id> \
  --apple-id "$APPLE_ID" \
  --team-id "$TEAM_ID" \
  --password "$APP_SPECIFIC_PASSWORD"
```

**Download full log:**
```bash
xcrun notarytool log <submission-id> \
  --apple-id "$APPLE_ID" \
  --team-id "$TEAM_ID" \
  --password "$APP_SPECIFIC_PASSWORD" \
  developer_log.json
```

### What to Do If Notarization Fails

1. **Check the notarization log** (see above)
2. **Review common errors** in this section
3. **Verify code signing** is correct
4. **Test locally** before running in CI/CD
5. **Check Apple System Status**: https://developer.apple.com/system-status/
   - Notarization service may be temporarily down
6. **Contact Apple Developer Support** if issue persists

## Additional Resources

### Official Apple Documentation

- **Notarization Overview**: https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution
- **notarytool Reference**: https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution/customizing_the_notarization_workflow
- **App-Specific Passwords**: https://support.apple.com/en-us/HT204397
- **Code Signing Guide**: https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/
- **Hardened Runtime**: https://developer.apple.com/documentation/security/hardened_runtime

### GitHub Documentation

- **GitHub Secrets**: https://docs.github.com/en/actions/security-guides/encrypted-secrets
- **GitHub Actions**: https://docs.github.com/en/actions
- **Organization Secrets**: https://docs.github.com/en/actions/security-guides/encrypted-secrets#creating-encrypted-secrets-for-an-organization

### Project Documentation

- **Build Scripts**: [scripts/README.md](../scripts/README.md#notarizesh)
- **Main README**: [README.md](../README.md#distribution)
- **Distribution Guide**: [README.md - Creating a Release Package](../README.md#creating-a-release-package)
- **CI/CD Workflow**: [.github/workflows/ci.yml](../.github/workflows/ci.yml)

### Apple Developer Resources

- **Apple Developer Account**: https://developer.apple.com/account/
- **Apple ID Management**: https://appleid.apple.com/
- **Developer System Status**: https://developer.apple.com/system-status/
- **Developer Forums**: https://developer.apple.com/forums/

### Tools and Commands

- **notarytool**: Apple's command-line tool for notarization (included with Xcode Command Line Tools)
- **codesign**: macOS code signing utility
- **stapler**: Utility to staple notarization tickets
- **security**: Keychain and certificate management

---

## Summary Checklist

Before submitting code for automated notarization, ensure:

- [ ] Apple Developer Program membership is active
- [ ] Developer ID certificate is installed and valid
- [ ] App-specific password generated at https://appleid.apple.com/
- [ ] Team ID retrieved from https://developer.apple.com/account
- [ ] All three GitHub Secrets added to repository:
  - [ ] `APPLE_ID`
  - [ ] `TEAM_ID`
  - [ ] `APP_SPECIFIC_PASSWORD`
- [ ] Secrets verified in repository settings
- [ ] Local notarization tested successfully
- [ ] Code signing and hardened runtime enabled
- [ ] Security best practices reviewed and implemented

**Next steps:**
1. Test notarization locally with `./scripts/notarize.sh Release`
2. Commit and push changes to trigger CI/CD
3. Monitor GitHub Actions workflow for notarization success
4. Download and test notarized app

**Questions or issues?** See [Verification and Troubleshooting](#verification-and-troubleshooting) or open a GitHub issue.
