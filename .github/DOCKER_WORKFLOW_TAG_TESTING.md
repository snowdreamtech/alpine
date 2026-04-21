# Docker Workflow Tag Trigger Testing Guide

## 📋 Overview

This document explains the tag trigger configuration for the Docker multi-platform build workflow and provides testing scenarios to verify the integration with Release-Please.

## 🏷️ Supported Tag Formats

### Primary Format (Release-Please Generated)

The workflow now supports Release-Please generated tags:

```yaml
tags:
  - "3.20-v*"    # Matches: 3.20-v1.0.0, 3.20-v1.2.3, etc.
  - "3.21-v*"    # Matches: 3.21-v1.0.0, 3.21-v2.0.0, etc.
  - "3.22-v*"    # Matches: 3.22-v1.0.0, 3.22-v1.5.2, etc.
  - "3.23-v*"    # Matches: 3.23-v1.0.0, 3.23-v2.1.0, etc.
```

### Legacy Formats (Backward Compatibility)

The workflow maintains backward compatibility with legacy tag formats:

```yaml
tags:
  - "[0-9]+.[0-9]+.[0-9]+"    # Matches: 1.2.3, 10.20.30
  - "v[0-9]+.[0-9]+.[0-9]+"   # Matches: v1.2.3, v10.20.30
  - "V[0-9]+.[0-9]+.[0-9]+"   # Matches: V1.2.3, V10.20.30
  - "alpine-*.*.*"            # Matches: alpine-3.23.1, alpine-1.0.0
  - "[0-9]+.[0-9]+"           # Matches: 1.2, 10.20
  - "v[0-9]+.[0-9]+"          # Matches: v1.2, v10.20
  - "V[0-9]+.[0-9]+"          # Matches: V1.2, V10.20
  - "alpine-*.*"              # Matches: alpine-3.23, alpine-1.0
  - "[0-9]+"                  # Matches: 1, 2, 10
  - "v[0-9]+"                 # Matches: v1, v2, v10
  - "V[0-9]+"                 # Matches: V1, V2, V10
  - "alpine-*"                # Matches: alpine-3.23, alpine-latest
```

## 🧪 Testing Scenarios

### Scenario 1: Release-Please Tag (Primary Use Case)

**Release-Please Configuration:**

```json
{
  "docker/3.23": "3.23.2"
}
```

**When you merge a Release-Please PR:**

- Release-Please creates tag: `3.23-v3.23.3`
- Docker workflow triggers: ✅ YES (matches `3.23-v*`)
- Matrix job runs: Alpine 3.23 only
- Generated Docker tags:

  ```
  snowdreamtech/alpine:3.23.3
  snowdreamtech/alpine:3.23
  snowdreamtech/alpine:3              # Only if is_latest=true
  snowdreamtech/alpine:3.23-latest
  snowdreamtech/alpine:latest         # Only if is_latest=true
  ```

### Scenario 2: Multiple Version Release

**Release-Please creates multiple tags:**

```bash
3.20-v3.20.9
3.23-v3.23.3
```

**Docker workflow behavior:**

- Triggers twice (once per tag)
- First run: Alpine 3.20 only
- Second run: Alpine 3.23 only
- No conflicts (isolated by matrix version)

### Scenario 3: Manual Tag Push (Legacy Format)

**Manual tag creation:**

```bash
git tag alpine-3.23-1.0.0
git push origin alpine-3.23-1.0.0
```

**Docker workflow behavior:**

- Triggers: ✅ YES (matches `alpine-*.*.*`)
- Matrix job runs: All versions (no version filter in tag)
- Generated Docker tags:

  ```
  snowdreamtech/alpine:1.0.0
  snowdreamtech/alpine:1.0
  snowdreamtech/alpine:1
  snowdreamtech/alpine:3.23-latest
  snowdreamtech/alpine:latest
  ```

### Scenario 4: Version-Specific Tag Filter

**Tag pushed:**

```bash
3.23-v1.2.3
```

**Build filter logic:**

```yaml
# In the build step
if: |
  steps.version-filter.outputs.skip != 'true' &&
  ((github.event_name != 'push' || !startsWith(github.ref, 'refs/tags/')) ||
  (startsWith(github.ref, format('refs/tags/{0}-', matrix.version))))
```

**Result:**

- Alpine 3.20: ❌ SKIPPED (tag doesn't start with `3.20-`)
- Alpine 3.21: ❌ SKIPPED (tag doesn't start with `3.21-`)
- Alpine 3.22: ❌ SKIPPED (tag doesn't start with `3.22-`)
- Alpine 3.23: ✅ BUILDS (tag starts with `3.23-`)

## 🔍 Tag Matching Matrix

| Git Tag | Trigger Pattern | Alpine 3.20 | Alpine 3.21 | Alpine 3.22 | Alpine 3.23 |
|---------|----------------|-------------|-------------|-------------|-------------|
| `3.20-v1.0.0` | `3.20-v*` | ✅ Build | ⏭️ Skip | ⏭️ Skip | ⏭️ Skip |
| `3.21-v2.0.0` | `3.21-v*` | ⏭️ Skip | ✅ Build | ⏭️ Skip | ⏭️ Skip |
| `3.22-v1.5.0` | `3.22-v*` | ⏭️ Skip | ⏭️ Skip | ✅ Build | ⏭️ Skip |
| `3.23-v3.23.3` | `3.23-v*` | ⏭️ Skip | ⏭️ Skip | ⏭️ Skip | ✅ Build |
| `alpine-3.23-1.0.0` | `alpine-*.*.*` | ✅ Build | ✅ Build | ✅ Build | ✅ Build |
| `v1.2.3` | `v[0-9]+.[0-9]+.[0-9]+` | ✅ Build | ✅ Build | ✅ Build | ✅ Build |
| `1.2.3` | `[0-9]+.[0-9]+.[0-9]+` | ✅ Build | ✅ Build | ✅ Build | ✅ Build |

## 🎯 Expected Docker Tags Output

### For Release-Please Tag: `3.23-v1.2.3`

**Extracted version:** `1.2.3` (via regex pattern `v?(\d+\.\d+\.\d+)`)

**Generated Docker tags:**

```
# Semantic version tags (from tag extraction)
snowdreamtech/alpine:1.2.3          # x.y.z
snowdreamtech/alpine:1.2            # x.y
snowdreamtech/alpine:1              # x (only if is_latest=true)

# Version-specific latest
snowdreamtech/alpine:3.23-latest

# Global latest (only if is_latest=true)
snowdreamtech/alpine:latest

# Same tags for GHCR
ghcr.io/snowdreamtech/alpine:1.2.3
ghcr.io/snowdreamtech/alpine:1.2
ghcr.io/snowdreamtech/alpine:1
ghcr.io/snowdreamtech/alpine:3.23-latest
ghcr.io/snowdreamtech/alpine:latest

# Same tags for Quay.io
quay.io/snowdreamtech/alpine:1.2.3
quay.io/snowdreamtech/alpine:1.2
quay.io/snowdreamtech/alpine:1
quay.io/snowdreamtech/alpine:3.23-latest
quay.io/snowdreamtech/alpine:latest
```

## 🧪 Manual Testing Commands

### Test 1: Simulate Release-Please Tag

```bash
# Create a test tag
git tag 3.23-v1.0.0-test
git push origin 3.23-v1.0.0-test

# Expected: Workflow triggers for Alpine 3.23 only
# Check: https://github.com/snowdreamtech/alpine/actions
```

### Test 2: Verify Tag Extraction

```bash
# Check what version will be extracted
echo "3.23-v1.2.3" | grep -oP 'v?\K\d+\.\d+\.\d+'
# Expected output: 1.2.3
```

### Test 3: Test Version Filter

```bash
# Push a tag for Alpine 3.20
git tag 3.20-v1.0.0
git push origin 3.20-v1.0.0

# Expected: Only Alpine 3.20 matrix job runs
# Alpine 3.21, 3.22, 3.23 should be skipped
```

## 🔧 Troubleshooting

### Issue 1: Workflow Not Triggering

**Symptom:** Tag pushed but workflow doesn't start

**Diagnosis:**

```bash
# Check if tag matches any pattern
git tag -l "3.23-v*"

# Verify tag format
git show-ref --tags | grep "3.23-v"
```

**Solution:**

- Ensure tag follows format: `{alpine_version}-v{semantic_version}`
- Example: `3.23-v1.2.3` ✅
- Not: `v3.23-1.2.3` ❌

### Issue 2: Wrong Version Building

**Symptom:** Tag `3.23-v1.0.0` triggers Alpine 3.20 build

**Diagnosis:**
Check the build filter condition in workflow logs:

```
startsWith(github.ref, format('refs/tags/{0}-', matrix.version))
```

**Solution:**

- Verify tag prefix matches exactly: `3.23-` not `3.23.`
- Check for typos in tag name

### Issue 3: Multiple Versions Building

**Symptom:** Single tag triggers all Alpine versions

**Diagnosis:**
This is expected for legacy tag formats like `alpine-*.*.*` or `v1.2.3`

**Solution:**

- Use Release-Please format for version-specific builds: `3.23-v1.2.3`
- Or accept that legacy formats build all versions

## 📊 Workflow Decision Tree

```
Tag Pushed
    │
    ├─ Matches "3.20-v*"? ──YES──> Build Alpine 3.20 only
    ├─ Matches "3.21-v*"? ──YES──> Build Alpine 3.21 only
    ├─ Matches "3.22-v*"? ──YES──> Build Alpine 3.22 only
    ├─ Matches "3.23-v*"? ──YES──> Build Alpine 3.23 only
    │
    └─ Matches legacy format? ──YES──> Build all Alpine versions
       (alpine-*.*.*, v*.*.*, etc.)
```

## ✅ Validation Checklist

Before merging changes to the workflow:

- [ ] Verify tag patterns match Release-Please output
- [ ] Test with a dummy tag push
- [ ] Confirm version filter works correctly
- [ ] Check Docker tags are generated as expected
- [ ] Validate multi-registry push succeeds
- [ ] Verify SBOM and signatures are created
- [ ] Test rollback scenario (delete tag)

## 🔗 Related Documentation

- [Release-Please Configuration](.release-please-config.json)
- [Release-Please Manifest](.release-please-manifest.json)
- [Docker Workflow](.github/workflows/docker.yml)
- [Docker Metadata Action](https://github.com/docker/metadata-action)

## 📝 Notes

- The workflow maintains backward compatibility with legacy tag formats
- Version-specific builds are controlled by the tag prefix (`3.23-v*`)
- Global `latest` tag is only assigned to `is_latest=true` versions
- Nightly builds do not update `latest` tags (by design)
