# Conda Builds with Witness Demo

This repository demonstrates how to integrate Witness attestations into conda package builds for Anaconda.

## Demo Overview

This demo shows:
1. Building conda packages with Witness attestations
2. Multi-signature strategy (file key + AWS KMS)
3. SLSA Level 3 compliance
4. Policy enforcement
5. Package verification workflow

## Prerequisites

- Conda/Miniconda installed
- Witness CLI installed
- AWS credentials configured (for KMS signing)
- Go 1.19+ (for policy evaluation)

## Quick Start

```bash
# Build a package with attestations
make build-numpy

# Verify the package
make verify-numpy

# Run the full demo
make demo
```

## Demo Structure

- `recipes/` - Conda package recipes
- `policies/` - Witness verification policies
- `scripts/` - Demo automation scripts
- `.github/workflows/` - GitHub Actions CI/CD

## Key Features Demonstrated

1. **Build Attestations**: Every conda build generates signed attestations
2. **SBOM Generation**: Automatic Software Bill of Materials
3. **Policy Enforcement**: Builds must meet security requirements
4. **Multi-Signature**: Both local keys and AWS KMS signing
5. **API Integration**: GraphQL queries to Archivista