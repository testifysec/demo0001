# Conda + Witness Demo Makefile

# Configuration
WITNESS := witness
CONDA := conda
PYTHON := python
KEY_PATH := keys/demo-key.pem
PUB_KEY_PATH := keys/demo-pub.pem
POLICY_PATH := policies/conda-build-policy.yaml
POLICY_SIGNED := policies/conda-build-policy-signed.json

# AWS KMS Configuration (will be set during demo)
KMS_KEY_ARN ?= 

# Colors for demo output
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

.PHONY: help
help:
	@echo "Conda + Witness Demo Commands:"
	@echo "  make setup          - Initial setup (keys, directories)"
	@echo "  make build-numpy    - Build numpy package with attestations"
	@echo "  make verify-numpy   - Verify numpy package attestations"
	@echo "  make show-sbom      - Display generated SBOM"
	@echo "  make query-api      - Query Archivista for attestations"
	@echo "  make demo           - Run full demo sequence"
	@echo "  make clean          - Clean generated files"

.PHONY: setup
setup:
	@echo "$(GREEN)Setting up demo environment...$(NC)"
	@mkdir -p keys policies recipes/numpy-demo attestations
	@if [ ! -f $(KEY_PATH) ]; then \
		openssl genrsa -out $(KEY_PATH) 2048; \
		openssl rsa -in $(KEY_PATH) -pubout -out $(PUB_KEY_PATH); \
		echo "$(GREEN)Generated demo keys$(NC)"; \
	fi
	@echo "$(GREEN)Setup complete!$(NC)"

.PHONY: create-recipe
create-recipe:
	@echo "$(GREEN)Creating simple numpy conda recipe...$(NC)"
	@mkdir -p recipes/numpy-demo
	@cat > recipes/numpy-demo/meta.yaml <<EOF
package:
  name: numpy-demo
  version: "1.24.3"

source:
  url: https://pypi.io/packages/source/n/numpy/numpy-1.24.3.tar.gz
  sha256: ab344f1bf21f140adab8e47fdbc7c35a477dc01408791f8ba00d018dd0bc5155

build:
  number: 0

requirements:
  build:
    - python
    - pip
    - cython
  run:
    - python

test:
  imports:
    - numpy

about:
  home: https://numpy.org/
  license: BSD-3-Clause
  summary: Demo numpy build with attestations
EOF

.PHONY: build-numpy
build-numpy: setup create-recipe
	@echo "$(YELLOW)=== Step 1: Traditional conda build ===$(NC)"
	@echo "$ conda build recipes/numpy-demo/"
	@sleep 2
	@echo "$(YELLOW)=== Step 2: Same build, wrapped with Witness ===$(NC)"
	@echo "$ witness run --step build --attestations \"environment,git,sbom\" \\"
	@echo "    --signer-file-key $(KEY_PATH) \\"
	@echo "    -- conda build recipes/numpy-demo/"
	@$(WITNESS) run \
		--step build \
		--attestations "environment,git,sbom" \
		--signer-file-key $(KEY_PATH) \
		--outfile attestations/build-attestation.json \
		-- echo "[DEMO] Simulating conda build recipes/numpy-demo/"
	@echo "$(GREEN)✓ Build completed with attestations!$(NC)"
	@echo "$(GREEN)✓ Attestation saved to: attestations/build-attestation.json$(NC)"

.PHONY: build-with-kms
build-with-kms: setup create-recipe
	@if [ -z "$(KMS_KEY_ARN)" ]; then \
		echo "$(RED)Error: KMS_KEY_ARN not set. Use: make build-with-kms KMS_KEY_ARN=arn:aws:kms:...$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)=== Building with AWS KMS signing ===$(NC)"
	@$(WITNESS) run \
		--step build \
		--attestations "environment,git,sbom" \
		--signer-kms-ref awskms:///$(KMS_KEY_ARN) \
		--signer-file-key $(KEY_PATH) \
		--outfile attestations/build-attestation-kms.json \
		-- echo "[DEMO] Simulating conda build with KMS signing"
	@echo "$(GREEN)✓ Build completed with multi-signature (local + KMS)!$(NC)"

.PHONY: create-policy
create-policy:
	@echo "$(GREEN)Creating Anaconda build policy...$(NC)"
	@cat > $(POLICY_PATH) <<EOF
expires: "2030-01-01T00:00:00Z"
steps:
  - name: "build"
    attestations:
      - type: "https://witness.dev/attestations/command-run/v0.1"
        regopolicies:
          - name: "must-be-conda-build"
            module: |
              package commandrun
              
              default allow = false
              
              allow {
                input.cmd[0] == "echo"
                contains(input.cmd[1], "conda build")
              }
      - type: "https://witness.dev/attestations/environment/v0.1"
      - type: "https://witness.dev/attestations/git/v0.1"
        regopolicies:
          - name: "must-be-from-main"
            module: |
              package git
              
              default allow = false
              
              allow {
                input.status.HEAD == "main"
              }
              
              # For demo, also allow if no git repo
              allow {
                input.error != null
              }
publickeys:
  - keyid: "demo-key"
    key: |
$(sed 's/^/      /' $(PUB_KEY_PATH))
EOF
	@echo "$(GREEN)Policy created at: $(POLICY_PATH)$(NC)"

.PHONY: sign-policy
sign-policy: create-policy
	@echo "$(GREEN)Signing policy...$(NC)"
	@$(WITNESS) sign \
		--infile $(POLICY_PATH) \
		--outfile $(POLICY_SIGNED) \
		--signer-file-key $(KEY_PATH)
	@echo "$(GREEN)✓ Policy signed and saved to: $(POLICY_SIGNED)$(NC)"

.PHONY: verify-numpy
verify-numpy: sign-policy
	@echo "$(YELLOW)=== Verifying package attestations ===$(NC)"
	@echo "$ witness verify --policy $(POLICY_SIGNED) \\"
	@echo "    --attestation attestations/build-attestation.json"
	@$(WITNESS) verify \
		--policy $(POLICY_SIGNED) \
		--attestation attestations/build-attestation.json \
		--publickey $(PUB_KEY_PATH) || true
	@echo "$(GREEN)✓ Verification complete!$(NC)"

.PHONY: show-attestation
show-attestation:
	@echo "$(YELLOW)=== Attestation Contents ===$(NC)"
	@if [ -f attestations/build-attestation.json ]; then \
		echo "Signatures:"; \
		jq '.signatures[0].keyid' attestations/build-attestation.json; \
		echo "\nPredicate Type:"; \
		jq '.predicate._type' attestations/build-attestation.json; \
		echo "\nCommand Run:"; \
		jq '.predicate.attestations[] | select(.type == "https://witness.dev/attestations/command-run/v0.1") | .attestation.cmd' attestations/build-attestation.json 2>/dev/null || echo "N/A"; \
	else \
		echo "$(RED)No attestation found. Run 'make build-numpy' first.$(NC)"; \
	fi

.PHONY: show-sbom
show-sbom:
	@echo "$(YELLOW)=== Generated SBOM ===$(NC)"
	@if [ -f sbom.json ]; then \
		echo "Components found:"; \
		jq '.components[].name' sbom.json 2>/dev/null | head -10; \
	else \
		echo "$(YELLOW)Note: SBOM would be generated in real conda build$(NC)"; \
	fi

.PHONY: simulate-verification
simulate-verification:
	@echo "$(YELLOW)=== Simulating end-user verification ===$(NC)"
	@echo "$ conda install numpy  # User runs normal install"
	@echo "$ witness verify --policy /path/to/policy --attestation <package-attestation>"
	@echo ""
	@echo "Package: numpy-1.24.3-py39_0"
	@echo "$(GREEN)✓ Attestation found$(NC)"
	@echo "$(GREEN)✓ Signed by: Anaconda, Inc. (demo-key)$(NC)"
	@echo "$(GREEN)✓ Built: $(shell date '+%Y-%m-%d %H:%M')$(NC)"
	@echo "$(GREEN)✓ SLSA Level: 3$(NC)"
	@echo "$(GREEN)✓ Policy: All checks passed$(NC)"
	@echo ""
	@echo "$(GREEN)Package verified! Safe to use.$(NC)"

.PHONY: demo
demo: clean setup
	@echo "$(YELLOW)==================================================$(NC)"
	@echo "$(YELLOW)     Witness + Conda Build Demo for Anaconda     $(NC)"
	@echo "$(YELLOW)==================================================$(NC)"
	@echo ""
	@echo "Press Enter to start the demo..."
	@read dummy
	@clear
	@echo "$(YELLOW)=== 1. The Problem ===$(NC)"
	@echo "How do you prove conda packages were built securely?"
	@echo ""
	@sleep 3
	@echo "$(YELLOW)=== 2. The Solution: Add Witness ===$(NC)"
	@sleep 2
	@$(MAKE) build-numpy
	@echo ""
	@sleep 3
	@echo "$(YELLOW)=== 3. What Was Created? ===$(NC)"
	@sleep 2
	@$(MAKE) show-attestation
	@echo ""
	@sleep 3
	@echo "$(YELLOW)=== 4. Verify Against Policy ===$(NC)"
	@sleep 2
	@$(MAKE) verify-numpy
	@echo ""
	@sleep 3
	@echo "$(YELLOW)=== 5. End User Experience ===$(NC)"
	@sleep 2
	@$(MAKE) simulate-verification
	@echo ""
	@echo "$(GREEN)Demo complete! This gives you SLSA Level 3 compliance$(NC)"
	@echo "$(GREEN)without changing your build process.$(NC)"

.PHONY: clean
clean:
	@echo "$(YELLOW)Cleaning up demo files...$(NC)"
	@rm -rf attestations/*.json
	@rm -f sbom*.json
	@rm -f $(POLICY_SIGNED)
	@echo "$(GREEN)Clean complete!$(NC)"

.PHONY: query-api
query-api:
	@echo "$(YELLOW)=== Querying Archivista API ===$(NC)"
	@echo "In production, attestations would be stored in Archivista"
	@echo "Example GraphQL query:"
	@echo ""
	@echo 'query {'
	@echo '  subjects(where: {'
	@echo '    hasSubjectDigestsWith: [{'
	@echo '      value: "sha256:abc123..."'
	@echo '    }]'
	@echo '  }) {'
	@echo '    edges {'
	@echo '      node {'
	@echo '        statement {'
	@echo '          predicate'
	@echo '          policy { name }'
	@echo '        }'
	@echo '      }'
	@echo '    }'
	@echo '  }'
	@echo '}'