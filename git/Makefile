.PHONY: init
init:
	cp ${PWD}/gitconfig ${HOME}/.gitconfig

.PHONY: clean
clean:
	rm ${HOME}/.gitconfig || true

# Extract target path from command line arguments
ARGS := $(filter-out distribute prevent-commit-develop,$(MAKECMDGOALS))
TARGET_PATH := $(firstword $(ARGS))

.PHONY: distribute
distribute: prevent-commit-develop

.PHONY: prevent-commit-develop
prevent-commit-develop:
	@if [ -z "$(TARGET_PATH)" ]; then \
		echo "❌ Error: Target path is not specified"; \
		echo ""; \
		echo "Usage: make distribute prevent-commit-develop <target-path>"; \
		echo ""; \
		echo "Example: make distribute prevent-commit-develop ~/my-project"; \
		exit 1; \
	fi
	@if [ ! -d "$(TARGET_PATH)/.git" ]; then \
		echo "❌ Error: $(TARGET_PATH) is not a git repository"; \
		echo "   Path: $(TARGET_PATH)"; \
		exit 1; \
	fi
	@echo "📦 Installing prevent-commit-develop hook to $(TARGET_PATH)/.git/hooks/"
	@mkdir -p "$(TARGET_PATH)/.git/hooks"
	@cp ${PWD}/hooks/prevent-commit-develop "$(TARGET_PATH)/.git/hooks/pre-commit"
	@chmod +x "$(TARGET_PATH)/.git/hooks/pre-commit"
	@echo "✅ Hook installed successfully!"
	@echo "   Location: $(TARGET_PATH)/.git/hooks/pre-commit"

# Dummy target to prevent make from treating paths as targets
%:
	@:
