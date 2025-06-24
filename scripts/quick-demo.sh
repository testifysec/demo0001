#!/bin/bash

# Quick demo for testing - runs in ~2 minutes

set -e

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${YELLOW}Quick Witness + Conda Demo${NC}"
echo ""

# Setup
make setup

# Build with attestations
echo -e "${YELLOW}Building click with attestations...${NC}"
make build-click

# Show what was created
echo ""
echo -e "${YELLOW}Attestation created:${NC}"
make show-attestation

# Verify
echo ""
echo -e "${YELLOW}Verifying against policy...${NC}"
make verify-click || echo -e "${YELLOW}(Verification requires policy setup)${NC}"

echo ""
echo -e "${GREEN}✓ Demo complete!${NC}"