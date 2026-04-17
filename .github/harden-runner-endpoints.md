# Harden Runner Endpoints Configuration

This directory contains centralized configuration for [Step Security Harden Runner](https://github.com/step-security/harden-runner) allowed endpoints.

## Files

- **harden-runner-endpoints.yml**: Centralized endpoint configuration with profiles
- **../scripts/sync-harden-runner.py**: Python script to sync endpoints to workflow files
- **../scripts/sync-harden-runner.sh**: Shell wrapper (delegates to Python script)

## Endpoint Profiles

### minimal

For simple workflows that only interact with GitHub:

- GitHub API and content delivery
- Mise installation

**Used by**: cache, dco, dependabot-auto-merge, dependabot-sync, goreleaser, label-sync, labeler, pr-title, stale

### standard

For workflows that install dependencies from package managers:

- All minimal endpoints
- Package managers (npm, pip, cargo, rubygems, etc.)
- OS package repositories (apt, yum, apk)

**Used by**: codeql, pages

### full

For CI/CD workflows with containers and security scanning:

- All standard endpoints
- Container registries (ghcr.io, gcr.io, ecr, acr, quay.io)
- Security scanning tools (trivy, osv-scanner, sigstore)

**Used by**: ci, cd

### audit

For security audit workflows:

- GitHub and mise endpoints
- Container registries (minimal)
- Security tools (trivy, sigstore, scorecard, osv)

**Used by**: nightly-audit, scorecard

## Usage

### Sync All Workflows

```bash
# Using Python (recommended)
python3 scripts/sync-harden-runner.py

# Using shell wrapper
sh scripts/sync-harden-runner.sh
```

### Add New Endpoint

1. Edit `.github/harden-runner-endpoints.yml`
2. Add the endpoint to the appropriate profile(s)
3. Run sync script to update all workflows
4. Review changes: `git diff .github/workflows/`
5. Commit changes

### Add New Workflow

1. Edit `.github/harden-runner-endpoints.yml`
2. Add workflow to `workflow_profiles` section
3. Choose appropriate profile (minimal/standard/full/audit)
4. Run sync script

## Example

Adding a new endpoint for all CI/CD workflows:

```yaml
# In harden-runner-endpoints.yml
full:
  - api.github.com:443
  # ... existing endpoints ...
  - new-service.example.com:443  # Add here
```

Then run:

```bash
python3 scripts/sync-harden-runner.py
```

## Benefits

1. **Single Source of Truth**: All endpoints defined in one place
2. **Consistency**: All workflows use the same endpoint lists
3. **Maintainability**: Easy to add/remove endpoints globally
4. **Documentation**: Clear profiles explain what each workflow needs
5. **Automation**: Script ensures all workflows stay in sync

## Requirements

- Python 3.6+ with PyYAML: `pip install pyyaml`
- Or use mise: `mise install python` (PyYAML included in project)

## Troubleshooting

### Blocked Endpoint Detected

If Harden Runner blocks a legitimate request:

1. Check the Harden Runner logs in GitHub Actions
2. Identify the blocked endpoint (domain:port)
3. Add it to the appropriate profile in `harden-runner-endpoints.yml`
4. Run sync script
5. Commit and push changes

### Script Errors

```bash
# Check Python and PyYAML
python3 --version
python3 -c "import yaml; print(yaml.__version__)"

# Install PyYAML if missing
pip3 install pyyaml
```

## References

- [Step Security Harden Runner](https://github.com/step-security/harden-runner)
- [GitHub Actions Security Best Practices](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)
