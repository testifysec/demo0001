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
# Run the 2-minute demo
./scripts/quick-demo.sh

# Or run the full interactive demo
./scripts/demo-script.sh
```

## Repository Structure

- `recipes/` - Real conda package recipes (numpy, pandas, scipy)
- `Makefile` - Demo commands for local testing
- `scripts/` - Demo automation scripts
- `policies/` - Witness policies for conda builds
- `keys/` - Test signing keys (FOR DEMO ONLY)
- `.github/workflows/` - GitHub Actions CI/CD with Witness

## GitHub Actions Workflow

The workflow uses a matrix strategy to build multiple packages in parallel with enhanced security:

1. **Setup Job**: Finds all recipes (click, pyyaml, requests)
2. **Build Job**: 
   - Uses Sigstore for ephemeral signing keys
   - Captures multiple attestations: git, github, environment, system-packages, secretscan
   - Stores attestations in public Archivista
   - Enables tracing for debugging
3. **Verify Job**: Queries Archivista for attestations
4. **Summary Job**: Reports build status with security details

## Local Commands

```bash
# Setup demo environment
make setup

# Build with attestations
make build-numpy

# Verify build
make verify-numpy

# Run full demo
make demo
```

## Recipes

- `click` (8.1.7) - Command line interface toolkit (builds fast!)
- `pyyaml` (6.0.1) - YAML parser and emitter
- `requests` (2.31.0) - HTTP library for Python

These packages were chosen because they:
- Build quickly (< 30 seconds)
- Have minimal dependencies
- Demonstrate real conda builds with attestations

## Key Features Demonstrated

1. **Build Attestations**: Every conda build generates signed attestations
2. **SBOM Generation**: Automatic Software Bill of Materials
3. **Policy Enforcement**: Builds must meet security requirements
4. **Multi-Signature**: Both local keys and AWS KMS signing
5. **API Integration**: GraphQL queries to Archivista