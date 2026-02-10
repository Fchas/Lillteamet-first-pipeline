# GHCR Setup & Organization Permission Fix

## Current Status
The workflow is configured to push Docker images to GHCR, but it's currently **skipped** because the `PAT_GHCR` secret is not configured.

You will see this warning in the workflow output:
```
⚠️ GHCR push skipped - PAT_GHCR secret not configured
```

This is normal - follow the options below to enable GHCR pushing.

---

## Problem
The GitHub organization blocks `GITHUB_TOKEN` from writing to GHCR with the error:
```
"denied: installation not allowed to Write organization package"
```

This requires either:
1. **Organization admin action** to allow the token, OR
2. **You** creating a Personal Access Token (PAT) as a workaround

---

## Solution 1: Organization Admin Fix (Recommended)

**Requires**: Organization admin access to https://github.com/organizations/Fchas

1. Go to **Settings** → **Actions** → **General**
2. Scroll to **"Workflow permissions"**
3. Enable **"Allow organization members to create packages"**
4. Check any other relevant GHCR/package permissions
5. Save changes

Once enabled by the admin, the workflow will automatically use `GITHUB_TOKEN` and you won't need to create a separate PAT.

**After org admin enables this:**
```bash
git commit --allow-empty -m "test: retrigger workflow after org permission fix"
git push origin main
```

---

## Solution 2: Personal Access Token (PAT) - DIY Workaround

**Use this if you don't have organization admin access**

### Step 1: Create a Personal Access Token

1. Go to https://github.com/settings/tokens/new (**your account**, not the org)
2. Fill in:
   - **Token name**: `GHCR PAT`
   - **Expiration**: 90 days (check back to refresh)
3. Select **Scopes**:
   - ✅ `write:packages` (Write packages to GHCR)
   - ✅ `read:packages` (Read packages from GHCR)
   - ✅ `repo` (Optional, for private repos)
4. Click **"Generate token"**
5. **Copy the token immediately** (you won't see it again!)

### Step 2: Add Token to Repository Secrets

1. Go to your repository: https://github.com/Fchas/Lillteamet-first-pipeline
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **"New repository secret"**
4. Fill in:
   - **Name**: `PAT_GHCR` (exactly this name)
   - **Secret**: Paste the token from Step 1
5. Click **"Add secret"**

### Step 3: Test the Workflow

Push a commit to trigger the workflow:
```bash
git commit --allow-empty -m "test: enable GHCR push with PAT"
git push origin main
```

Check the workflow at: https://github.com/Fchas/Lillteamet-first-pipeline/actions

The GHCR push should now succeed! ✅

---

## Security Best Practices

- **⚠️ Token Scope**: Keep the PAT limited to only `write:packages` + `read:packages`
- **⚠️ Token Expiration**: Set an expiration date (90 days recommended) and refresh periodically
- **⚠️ Never Commit**: Never hard-code the token - GitHub will reject it immediately
- **⚠️ Regenerate if Leaked**: If the token is ever exposed, regenerate it at https://github.com/settings/tokens
- For production, consider **GitHub Apps** for more granular permissions

---

## Verification

After setting up the secret, the workflow will:
1. ✅ Build Docker image with lowercase GHCR name
2. ✅ Run Trivy security scan (non-blocking)
3. ✅ Login to GHCR with your PAT
4. ✅ Push image to `ghcr.io/fchas/lillteamet-first-pipeline:latest`

You can verify the image was pushed at:
https://github.com/Fchas/Lillteamet-first-pipeline/pkgs/container/lillteamet-first-pipeline

---

## Uninstall / Cleanup

To disable GHCR pushing:
1. Go to repo **Settings** → **Secrets and variables** → **Actions**
2. Delete the `PAT_GHCR` secret
3. The workflow will skip the push step automatically (showing the warning)
