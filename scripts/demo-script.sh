#!/bin/bash

# Conda + Witness Demo Script
# This script automates the demo flow for the Anaconda presentation

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Demo functions
function print_step() {
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}$1${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    sleep 2
}

function run_command() {
    echo -e "${BLUE}$ $1${NC}"
    sleep 1
    eval $1
}

function pause() {
    echo ""
    echo -e "${GREEN}Press Enter to continue...${NC}"
    read
}

# Demo Start
clear
echo -e "${YELLOW}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║     Witness + Conda Build Demo for Anaconda              ║${NC}"
echo -e "${YELLOW}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "This demo shows how to add supply chain security to conda builds"
echo "without changing your existing build process."
pause

# Step 1: The Problem
print_step "Step 1: The Problem - Current conda build process"
run_command "ls recipes/numpy-demo/"
run_command "cat recipes/numpy-demo/meta.yaml | head -15"
echo ""
echo -e "${RED}❓ Question: How do you prove this was built securely?${NC}"
echo -e "${RED}❓ Can customers verify the build environment?${NC}"
echo -e "${RED}❓ Can you prove no tampering occurred?${NC}"
pause

# Step 2: Add Witness
print_step "Step 2: The Solution - Add Witness to your build"
echo "Same conda build command, just wrapped with witness run:"
echo ""
run_command "witness run --step build --signer-file-key keys/demo-key.pem --attestations \"environment,git,sbom\" -- conda build recipes/numpy-demo/"
echo ""
echo -e "${GREEN}✓ Build completed with signed attestations!${NC}"
pause

# Step 3: Show what was created
print_step "Step 3: Examining the attestations"
run_command "ls -la attestations/"
echo ""
echo "Let's look inside the attestation:"
run_command "cat attestations/build-attestation.json | jq '.signatures[0].keyid'"
echo ""
echo "Build environment captured:"
run_command "cat attestations/build-attestation.json | jq '.predicate.attestations[] | select(.type == \"https://witness.dev/attestations/environment/v0.1\") | .attestation | {hostname, os, user}'"
pause

# Step 4: Policy enforcement
print_step "Step 4: Policy-based verification"
echo "Create a policy that defines trusted builds:"
run_command "cat policies/conda-build-policy.yaml | head -20"
echo ""
echo "Verify the build meets policy requirements:"
run_command "witness verify --policy policies/conda-build-policy-signed.json --attestation attestations/build-attestation.json --publickey keys/demo-pub.pem"
echo ""
echo -e "${GREEN}✓ Build passed all policy checks!${NC}"
pause

# Step 5: Multi-signature with KMS
print_step "Step 5: Enterprise signing with AWS KMS"
echo "For production, use hardware-backed keys:"
echo ""
echo -e "${BLUE}$ witness run --step build \\
    --signer-kms-ref awskms:///arn:aws:kms:us-east-1:123456:key/abc-def \\
    --signer-file-key keys/demo-key.pem \\
    -- conda build recipes/numpy-demo/${NC}"
echo ""
echo "This provides:"
echo "- Hardware security module protection"
echo "- Audit trail in CloudTrail"
echo "- Multi-signature attestations"
pause

# Step 6: SBOM Generation
print_step "Step 6: Automatic SBOM generation"
echo "Witness can generate SBOMs during build:"
run_command "witness run --step build --attestor-sbom-export sbom-cyclonedx.json --signer-file-key keys/demo-key.pem -- echo 'Building with SBOM...'"
echo ""
echo "SBOM contains all dependencies:"
echo '{"components": [{"name": "numpy"}, {"name": "python"}, {"name": "cython"}]}'
pause

# Step 7: End user verification
print_step "Step 7: End-user package verification"
echo "Future state: Users verify packages before installation"
echo ""
echo -e "${BLUE}$ conda install numpy${NC}"
echo -e "${BLUE}$ witness verify --policy anaconda-policy.yaml --subject numpy-1.24.3.tar.bz2${NC}"
echo ""
echo "Package: numpy-1.24.3-py39_0"
echo -e "${GREEN}✓ Attestation found${NC}"
echo -e "${GREEN}✓ Signed by: Anaconda, Inc. (AWS KMS)${NC}"
echo -e "${GREEN}✓ Built: $(date '+%Y-%m-%d %H:%M CDT')${NC}"
echo -e "${GREEN}✓ SLSA Level: 3${NC}"
echo -e "${GREEN}✓ No vulnerabilities in SBOM${NC}"
echo ""
echo -e "${GREEN}Package verified! Safe to use.${NC}"
pause

# Step 8: GraphQL API Integration
print_step "Step 8: Trust Center API Integration"
echo "Query attestations via GraphQL:"
echo ""
cat << 'EOF'
query {
  subjects(where: {
    hasSubjectDigestsWith: [{
      value: "sha256:abc123..."
    }]
  }) {
    edges {
      node {
        statement {
          predicate
          policy {
            name
            verified
          }
        }
      }
    }
  }
}
EOF
pause

# Summary
print_step "Summary: What we achieved"
echo -e "${GREEN}✓ Same conda build process${NC}"
echo -e "${GREEN}✓ Cryptographic proof of build integrity${NC}"
echo -e "${GREEN}✓ SLSA Level 3 compliance${NC}"
echo -e "${GREEN}✓ Policy-based verification${NC}"
echo -e "${GREEN}✓ Multi-signature support${NC}"
echo -e "${GREEN}✓ Customer-verifiable packages${NC}"
echo ""
echo -e "${YELLOW}This gives Anaconda:${NC}"
echo "1. Internal Development Security"
echo "2. SLSA Level 3 Package Builds"
echo "3. Customer-Facing Trust Center"
echo ""
echo -e "${GREEN}Ready to implement in 8 weeks!${NC}"