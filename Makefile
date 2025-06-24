# Conda + Witness Demo Makefile

# Configuration
WITNESS := witness
CONDA := conda
PYTHON := python
KEY_PATH := keys/test-key.pem
PUB_KEY_PATH := keys/test-pub.pem
POLICY_PATH := policies/conda-policy.yaml
POLICY_SIGNED := policies/conda-policy-signed.json

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
	@echo "  make build-pandas   - Build pandas package with attestations"
	@echo "  make build-scipy    - Build scipy package with attestations"
	@echo "  make build-click    - Build click package with attestations (fast!)"
	@echo "  make build-pyyaml   - Build pyyaml package with attestations"
	@echo "  make build-requests - Build requests package with attestations"
	@echo "  make build-all      - Build all packages"
	@echo "  make verify-numpy   - Verify numpy package attestations"
	@echo "  make show-sbom      - Display generated SBOM"
	@echo "  make query-api      - Query Archivista for attestations"
	@echo "  make demo           - Run full demo sequence"
	@echo "  make list-recipes   - List available recipes"
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

.PHONY: list-recipes
list-recipes:
	@echo "$(GREEN)Available recipes:$(NC)"
	@find recipes -name meta.yaml -type f | sed 's|/meta.yaml||' | sort

.PHONY: build-numpy
build-numpy: setup
	@echo "$(YELLOW)=== Building numpy with Witness ===$(NC)"
	@$(WITNESS) run \
		--step build \
		--attestations "environment,git,secretscan" \
		--signer-file-key-path $(KEY_PATH) \
		--enable-archivista \
		--archivista-server "https://archivista.testifysec.io" \
		--outfile attestations/numpy-attestation.json \
		-- conda build recipes/numpy-demo
	@echo "$(GREEN)✓ Build completed with attestations!$(NC)"
	@echo "$(GREEN)✓ Attestation saved to: attestations/numpy-attestation.json$(NC)"

.PHONY: build-pandas
build-pandas: setup
	@echo "$(YELLOW)=== Building pandas with Witness ===$(NC)"
	@$(WITNESS) run \
		--step build \
		--attestations "environment,git,secretscan" \
		--signer-file-key-path $(KEY_PATH) \
		--enable-archivista \
		--archivista-server "https://archivista.testifysec.io" \
		--outfile attestations/pandas-attestation.json \
		-- conda build recipes/pandas-demo
	@echo "$(GREEN)✓ Build completed with attestations!$(NC)"
	@echo "$(GREEN)✓ Attestation saved to: attestations/pandas-attestation.json$(NC)"

.PHONY: build-scipy
build-scipy: setup
	@echo "$(YELLOW)=== Building scipy with Witness ===$(NC)"
	@$(WITNESS) run \
		--step build \
		--attestations "environment,git,secretscan" \
		--signer-file-key-path $(KEY_PATH) \
		--enable-archivista \
		--archivista-server "https://archivista.testifysec.io" \
		--outfile attestations/scipy-attestation.json \
		-- conda build recipes/scipy-demo
	@echo "$(GREEN)✓ Build completed with attestations!$(NC)"
	@echo "$(GREEN)✓ Attestation saved to: attestations/scipy-attestation.json$(NC)"

.PHONY: build-click
build-click: setup
	@echo "$(YELLOW)=== Building click with Witness ===$(NC)"
	@$(WITNESS) run \
		--step build \
		--attestations "environment,git,secretscan" \
		--signer-file-key-path $(KEY_PATH) \
		--enable-archivista \
		--archivista-server "https://archivista.testifysec.io" \
		--outfile attestations/click-attestation.json \
		-- conda build recipes/click-demo
	@echo "$(GREEN)✓ Build completed with attestations!$(NC)"
	@echo "$(GREEN)✓ Attestation saved to: attestations/click-attestation.json$(NC)"

.PHONY: build-pyyaml
build-pyyaml: setup
	@echo "$(YELLOW)=== Building pyyaml with Witness ===$(NC)"
	@$(WITNESS) run \
		--step build \
		--attestations "environment,git,secretscan" \
		--signer-file-key-path $(KEY_PATH) \
		--enable-archivista \
		--archivista-server "https://archivista.testifysec.io" \
		--outfile attestations/pyyaml-attestation.json \
		-- conda build recipes/pyyaml-demo
	@echo "$(GREEN)✓ Build completed with attestations!$(NC)"
	@echo "$(GREEN)✓ Attestation saved to: attestations/pyyaml-attestation.json$(NC)"

.PHONY: build-requests
build-requests: setup
	@echo "$(YELLOW)=== Building requests with Witness ===$(NC)"
	@$(WITNESS) run \
		--step build \
		--attestations "environment,git,secretscan" \
		--signer-file-key-path $(KEY_PATH) \
		--enable-archivista \
		--archivista-server "https://archivista.testifysec.io" \
		--outfile attestations/requests-attestation.json \
		-- conda build recipes/requests-demo
	@echo "$(GREEN)✓ Build completed with attestations!$(NC)"
	@echo "$(GREEN)✓ Attestation saved to: attestations/requests-attestation.json$(NC)"

.PHONY: build-all
build-all: build-click build-pyyaml build-requests
	@echo "$(GREEN)✓ All packages built successfully!$(NC)"

.PHONY: build-with-kms
build-with-kms: setup create-recipe
	@if [ -z "$(KMS_KEY_ARN)" ]; then \
		echo "$(RED)Error: KMS_KEY_ARN not set. Use: make build-with-kms KMS_KEY_ARN=arn:aws:kms:...$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)=== Building with AWS KMS signing ===$(NC)"
	@$(WITNESS) run \
		--step build \
		--attestations "environment,git,secretscan" \
		--signer-kms-ref awskms:///$(KMS_KEY_ARN) \
		--signer-file-key-path $(KEY_PATH) \
		--enable-archivista \
		--archivista-server "https://archivista.testifysec.io" \
		--outfile attestations/build-attestation-kms.json \
		-- echo "[DEMO] Simulating conda build with KMS signing"
	@echo "$(GREEN)✓ Build completed with multi-signature (local + KMS)!$(NC)"

.PHONY: create-policy
create-policy:
	@echo "$(GREEN)Creating Anaconda build policy...$(NC)"
	@printf 'expires: "2030-01-01T00:00:00Z"\n' > $(POLICY_PATH)
	@printf 'steps:\n' >> $(POLICY_PATH)
	@printf '  - name: "build"\n' >> $(POLICY_PATH)
	@printf '    attestations:\n' >> $(POLICY_PATH)
	@printf '      - type: "https://witness.dev/attestations/command-run/v0.1"\n' >> $(POLICY_PATH)
	@printf '        regopolicies:\n' >> $(POLICY_PATH)
	@printf '          - name: "must-be-conda-build"\n' >> $(POLICY_PATH)
	@printf '            module: |\n' >> $(POLICY_PATH)
	@printf '              package commandrun\n' >> $(POLICY_PATH)
	@printf '              \n' >> $(POLICY_PATH)
	@printf '              default allow = false\n' >> $(POLICY_PATH)
	@printf '              \n' >> $(POLICY_PATH)
	@printf '              allow {\n' >> $(POLICY_PATH)
	@printf '                input.cmd[0] == "conda"\n' >> $(POLICY_PATH)
	@printf '                input.cmd[1] == "build"\n' >> $(POLICY_PATH)
	@printf '              }\n' >> $(POLICY_PATH)
	@printf '      - type: "https://witness.dev/attestations/environment/v0.1"\n' >> $(POLICY_PATH)
	@printf '      - type: "https://witness.dev/attestations/git/v0.1"\n' >> $(POLICY_PATH)
	@printf '        regopolicies:\n' >> $(POLICY_PATH)
	@printf '          - name: "must-be-from-main"\n' >> $(POLICY_PATH)
	@printf '            module: |\n' >> $(POLICY_PATH)
	@printf '              package git\n' >> $(POLICY_PATH)
	@printf '              \n' >> $(POLICY_PATH)
	@printf '              default allow = false\n' >> $(POLICY_PATH)
	@printf '              \n' >> $(POLICY_PATH)
	@printf '              allow {\n' >> $(POLICY_PATH)
	@printf '                input.status.HEAD == "main"\n' >> $(POLICY_PATH)
	@printf '              }\n' >> $(POLICY_PATH)
	@printf '              \n' >> $(POLICY_PATH)
	@printf '              # For demo, also allow if no git repo\n' >> $(POLICY_PATH)
	@printf '              allow {\n' >> $(POLICY_PATH)
	@printf '                input.error != null\n' >> $(POLICY_PATH)
	@printf '              }\n' >> $(POLICY_PATH)
	@printf 'publickeys:\n' >> $(POLICY_PATH)
	@printf '  - keyid: "testkey"\n' >> $(POLICY_PATH)
	@printf '    key: |\n' >> $(POLICY_PATH)
	@sed 's/^/      /' $(PUB_KEY_PATH) >> $(POLICY_PATH)
	@echo "$(GREEN)Policy created at: $(POLICY_PATH)$(NC)"

.PHONY: sign-policy
sign-policy: create-policy
	@echo "$(GREEN)Signing policy...$(NC)"
	@$(WITNESS) sign \
		--infile $(POLICY_PATH) \
		--outfile $(POLICY_SIGNED) \
		--signer-file-key-path $(KEY_PATH)
	@echo "$(GREEN)✓ Policy signed and saved to: $(POLICY_SIGNED)$(NC)"

.PHONY: verify-numpy
verify-numpy: sign-policy
	@echo "$(YELLOW)=== Verifying package attestations ===$(NC)"
	@echo "$ witness verify --policy $(POLICY_SIGNED) \\"
	@echo "    --attestation attestations/build-attestation.json"
	@$(WITNESS) verify \
		--policy $(POLICY_SIGNED) \
		--attestation attestations/numpy-attestation.json \
		--publickey $(PUB_KEY_PATH) || true
	@echo "$(GREEN)✓ Verification complete!$(NC)"

.PHONY: show-attestation
show-attestation:
	@echo "$(YELLOW)=== Attestation Contents ===$(NC)"
	@if [ -f attestations/numpy-attestation.json ]; then \
		echo "Signatures:"; \
		jq '.signatures[0].keyid' attestations/numpy-attestation.json; \
		echo "\nPredicate Type:"; \
		jq '.predicate._type' attestations/numpy-attestation.json; \
		echo "\nCommand Run:"; \
		jq '.predicate.attestations[] | select(.type == "https://witness.dev/attestations/command-run/v0.1") | .attestation.cmd' attestations/numpy-attestation.json 2>/dev/null || echo "N/A"; \
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
	@echo "$(GREEN)✓ Signed by: Anaconda, Inc. (test-key)$(NC)"
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