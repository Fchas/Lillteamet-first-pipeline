# GHCR Setup & Organization Permission Fix

## Problem
The workflow fails with: `"denied: installation not allowed to Write organization package"`

This is a GitHub organization-level setting blocking `GITHUB_TOKEN` from writing to GHCR.

---

## Solution 1: Organization Admin Fix (Recommended)

**Requires**: Organization admin access to https://github.com/organizations/Fchas

1. Go to **Settings** → **Actions** → **General**
2. Scroll to **"Workflow permissions"**
3. Ensure **"Allow GitHub Actions to create and approve pull requests"** is enabled
4. Check **"Allow GitHub Actions to write to organization packages"** (or equivalent)
5. Save changes

Once enabled, the workflow will use `GITHUB_TOKEN` automatically.

---

## Solution 2: Personal Access Token (PAT) - Workaround

**Use this if you don't have organization admin access**

### Step 1: Create a Personal Access Token

1. Go to https://github.com/settings/tokens/new
2. **Token name**: `PAT_GHCR`
3. **Expiration**: 90 days (or your preference)
4. **Scopes**: Select:
   - ✅ `write:packages` - Write packages to GHCR
   - ✅ `read:packages` - Read packages from GHCR
   - ✅ `delete:packages` - Delete packages if needed
5. Click **"Generate token"**
6. **Copy the token** (you won't see it again)

### Step 2: Add Token to Repository Secrets

1. Go to your repository: https://github.com/Fchas/Lillteamet-first-pipeline
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **"New repository secret"**
4. **Name**: `PAT_GHCR`
5. **Secret**: Paste the token from Step 1
6. Click **"Add secret"**

### Step 3: Verify Workflow

The workflow is already configured to use `secrets.PAT_GHCR`. Your next push to main will use this token to authenticate with GHCR.

---

## Security Notes

- **PAT has broad permissions** - only use it in trusted repositories
- **Token expires** - refresh periodically (check expiration date)
- **Never commit the token** - it's stored as a GitHub secret
- For production, consider using **GitHub Apps** for more granular permissions

---

## Testing

Run a test by pushing a commit to the main branch:
```bash
git commit --allow-empty -m "test: trigger workflow"
git push origin main
```

Check the workflow status at:
https://github.com/Fchas/Lillteamet-first-pipeline/actions
