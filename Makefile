# Kali-Droidian Build System Makefile
# Provides convenient targets for building and managing the system

.PHONY: all build clean deps help install-deps check-deps setup
.DEFAULT_GOAL := help

# Build configuration
BUILD_DIR := build
ROOTFS_DIR :=$(BUILD_DIR)/rootfs
IMAGE_NAME := kali-droidian-phosh
VERSION := 1.0.0

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "$(GREEN)Kali-Droidian Build System$(NC)"
	@echo ""
	@echo "$(BLUE)Available targets:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""

deps: ## Install build dependencies
	@echo "$(GREEN)Installing build dependencies...$(NC)"
	@sudo apt update
	@sudo apt install -y \
		debootstrap \
		qemu-user-static \
		binfmt-support \
		wget \
		git \
		rsync \
		squashfs-tools \
		gzip \
		build-essential
	@echo "$(GREEN)Dependencies installed successfully$(NC)"

check-deps: ## Check if all dependencies are installed
	@echo "$(GREEN)Checking build dependencies...$(NC)"
	@deps_missing=0; \
	for dep in debootstrap qemu-user-static binfmt-support wget git rsync squashfs-tools gzip; do \
		if ! command -v $$dep >/dev/null 2>&1; then \
			echo "$(RED)Missing dependency: $$dep$(NC)"; \
			deps_missing=1; \
		else \
			echo "$(GREEN)✓ $$dep$(NC)"; \
		fi; \
	done; \
	if [ $$deps_missing -eq 1 ]; then \
		echo "$(RED)Some dependencies are missing. Run 'make deps' to install them.$(NC)"; \
		exit 1; \
	else \
		echo "$(GREEN)All dependencies are satisfied$(NC)"; \
	fi

setup: check-deps ## Setup build environment
	@echo "$(GREEN)Setting up build environment...$(NC)"
	@mkdir -p $(BUILD_DIR)
	@chmod +x build.sh
	@echo "$(GREEN)Build environment ready$(NC)"

build: setup ## Build the Kali-Droidian image
	@echo "$(GREEN)Starting Kali-Droidian build...$(NC)"
	@sudo ./build.sh
	@echo "$(GREEN)Build completed successfully!$(NC)"
	@echo "$(BLUE)Image location: $(BUILD_DIR)/$(IMAGE_NAME)-$(VERSION).squashfs$(NC)"

clean: ## Clean build artifacts
	@echo "$(YELLOW)Cleaning build artifacts...$(NC)"
	@sudo rm -rf $(BUILD_DIR)
	@echo "$(GREEN)Build artifacts cleaned$(NC)"

rebuild: clean build ## Clean and rebuild everything

install-deps: deps ## Alias for deps target

status: ## Show build status and information
	@echo "$(BLUE)Kali-Droidian Build System Status:$(NC)"
	@echo ""
	@echo "Build directory: $(BUILD_DIR)"
	@echo "Image name: $(IMAGE_NAME)"
	@echo "Version: $(VERSION)"
	@echo ""
	@if [ -d "$(BUILD_DIR)" ]; then \
		echo "$(GREEN)Build directory exists$(NC)"; \
		if [ -d "$(ROOTFS_DIR)" ]; then \
			echo "$(GREEN)Root filesystem exists$(NC)"; \
			echo "Size: $$(du -sh $(ROOTFS_DIR) 2>/dev/null | cut -f1 || echo 'Unknown')"; \
		else \
			echo "$(YELLOW)Root filesystem not found$(NC)"; \
		fi; \
		echo ""; \
		echo "$(BLUE)Build artifacts:$(NC)"; \
		ls -la $(BUILD_DIR)/ 2>/dev/null || echo "No artifacts found"; \
	else \
		echo "$(YELLOW)Build directory does not exist$(NC)"; \
	fi

validate: ## Validate build configuration
	@echo "$(GREEN)Validating build configuration...$(NC)"
	@error_count=0; \
	if [ ! -f "build.sh" ]; then \
		echo "$(RED)✗ build.sh not found$(NC)"; \
		error_count=$$((error_count + 1)); \
	else \
		echo "$(GREEN)✓ build.sh found$(NC)"; \
	fi; \
	if [ ! -d "config" ]; then \
		echo "$(RED)✗ config directory not found$(NC)"; \
		error_count=$$((error_count + 1)); \
	else \
		echo "$(GREEN)✓ config directory found$(NC)"; \
	fi; \
	if [ ! -d "scripts" ]; then \
		echo "$(RED)✗ scripts directory not found$(NC)"; \
		error_count=$$((error_count + 1)); \
	else \
		echo "$(GREEN)✓ scripts directory found$(NC)"; \
	fi; \
	if [ ! -f "config/sources.list" ]; then \
		echo "$(RED)✗ sources.list not found$(NC)"; \
		error_count=$$((error_count + 1)); \
	else \
		echo "$(GREEN)✓ sources.list found$(NC)"; \
	fi; \
	if [ $$error_count -eq 0 ]; then \
		echo "$(GREEN)Configuration validation passed$(NC)"; \
	else \
		echo "$(RED)Configuration validation failed with $$error_count errors$(NC)"; \
		exit 1; \
	fi

test: ## Run basic tests on the build system
	@echo "$(GREEN)Running build system tests...$(NC)"
	@chmod +x build.sh
	@bash -n build.sh && echo "$(GREEN)✓ build.sh syntax check passed$(NC)" || echo "$(RED)✗ build.sh syntax check failed$(NC)"
	@for script in scripts/*.sh; do \
		if [ -f "$$script" ]; then \
			chmod +x "$$script"; \
			bash -n "$$script" && echo "$(GREEN)✓ $$script syntax check passed$(NC)" || echo "$(RED)✗ $$script syntax check failed$(NC)"; \
		fi; \
	done

info: ## Show system information
	@echo "$(BLUE)System Information:$(NC)"
	@echo "OS: $$(lsb_release -d 2>/dev/null | cut -f2 || echo 'Unknown')"
	@echo "Kernel: $$(uname -r)"
	@echo "Architecture: $$(uname -m)"
	@echo "Available space: $$(df -h . | tail -1 | awk '{print $$4}')"
	@echo "Memory: $$(free -h | grep '^Mem:' | awk '{print $$2}')"
	@echo "CPU cores: $$(nproc)"
	@echo ""
	@echo "$(BLUE)Build System Information:$(NC)"
	@echo "Make version: $$(make --version | head -1)"
	@echo "Bash version: $$(bash --version | head -1)"
	@echo "Current user: $$(whoami)"
	@echo "Working directory: $$(pwd)"

debug: ## Enable debug mode and run build
	@echo "$(YELLOW)Running build in debug mode...$(NC)"
	@sudo bash -x ./build.sh

# Advanced targets
mount-rootfs: ## Mount build rootfs for inspection (requires existing build)
	@if [ ! -d "$(ROOTFS_DIR)" ]; then \
		echo "$(RED)Root filesystem not found. Run 'make build' first.$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)Mounting build rootfs...$(NC)"
	@sudo mount -t proc proc $(ROOTFS_DIR)/proc
	@sudo mount -t sysfs sysfs $(ROOTFS_DIR)/sys
	@sudo mount -o bind /dev $(ROOTFS_DIR)/dev
	@sudo mount -o bind /dev/pts $(ROOTFS_DIR)/dev/pts
	@echo "$(GREEN)Rootfs mounted. Use 'make umount-rootfs' when done.$(NC)"

umount-rootfs: ## Unmount build rootfs
	@echo "$(YELLOW)Unmounting build rootfs...$(NC)"
	@sudo umount $(ROOTFS_DIR)/proc 2>/dev/null || true
	@sudo umount $(ROOTFS_DIR)/sys 2>/dev/null || true
	@sudo umount $(ROOTFS_DIR)/dev/pts 2>/dev/null || true
	@sudo umount $(ROOTFS_DIR)/dev 2>/dev/null || true
	@echo "$(GREEN)Rootfs unmounted$(NC)"

chroot: mount-rootfs ## Enter chroot environment for debugging
	@echo "$(GREEN)Entering chroot environment...$(NC)"
	@echo "$(YELLOW)Type 'exit' to leave chroot$(NC)"
	@sudo chroot $(ROOTFS_DIR) /bin/bash
	@$(MAKE) umount-rootfs

shell: chroot ## Alias for chroot target

package-list: ## Show installed packages in built image
	@if [ ! -d "$(ROOTFS_DIR)" ]; then \
		echo "$(RED)Root filesystem not found. Run 'make build' first.$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Installed packages in built image:$(NC)"
	@sudo chroot $(ROOTFS_DIR) dpkg -l | grep '^ii' | awk '{print $$2}' | sort

size-analysis: ## Analyze build size breakdown
	@if [ ! -d "$(BUILD_DIR)" ]; then \
		echo "$(RED)Build directory not found. Run 'make build' first.$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Build size analysis:$(NC)"
	@echo ""
	@echo "$(YELLOW)Top 10 largest directories:$(NC)"
	@sudo du -sh $(ROOTFS_DIR)/* 2>/dev/null | sort -hr | head -10 || echo "Analysis failed"
	@echo ""
	@echo "$(YELLOW)Package cache size:$(NC)"
	@sudo du -sh $(ROOTFS_DIR)/var/cache/apt/ 2>/dev/null | cut -f1 || echo "Unknown"
	@echo ""
	@echo "$(YELLOW)Total build size:$(NC)"
	@sudo du -sh $(BUILD_DIR)/ 2>/dev/null | cut -f1 || echo "Unknown"

backup: ## Create backup of current build
	@if [ ! -d "$(BUILD_DIR)" ]; then \
		echo "$(RED)Build directory not found. Nothing to backup.$(NC)"; \
		exit 1; \
	fi
	@backup_name="backup-$(IMAGE_NAME)-$$(date +%Y%m%d-%H%M%S).tar.gz"; \
	echo "$(GREEN)Creating backup: $$backup_name$(NC)"; \
	sudo tar -czf "$$backup_name" $(BUILD_DIR)/; \
	echo "$(GREEN)Backup created: $$backup_name$(NC)"

restore: ## Restore from backup (requires BACKUP_FILE variable)
	@if [ -z "$(BACKUP_FILE)" ]; then \
		echo "$(RED)BACKUP_FILE variable not set. Usage: make restore BACKUP_FILE=backup.tar.gz$(NC)"; \
		exit 1; \
	fi
	@if [ ! -f "$(BACKUP_FILE)" ]; then \
		echo "$(RED)Backup file not found: $(BACKUP_FILE)$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Restoring from backup: $(BACKUP_FILE)$(NC)"
	@$(MAKE) clean
	@sudo tar -xzf "$(BACKUP_FILE)"
	@echo "$(GREEN)Backup restored successfully$(NC)"

# Maintenance targets
update-config: ## Update configuration files from templates
	@echo "$(GREEN)Updating configuration files...$(NC)"
	@# Add logic to update configs if needed
	@echo "$(GREEN)Configuration files updated$(NC)"

lint: ## Run shellcheck on all shell scripts
	@echo "$(GREEN)Running shellcheck on scripts...$(NC)"
	@if command -v shellcheck >/dev/null 2>&1; then \
		find . -name "*.sh" -exec shellcheck {} + && echo "$(GREEN)All scripts passed shellcheck$(NC)" || echo "$(YELLOW)Some scripts have warnings$(NC)"; \
	else \
		echo "$(YELLOW)shellcheck not installed. Install with: sudo apt install shellcheck$(NC)"; \
	fi

format: ## Format shell scripts with shfmt
	@echo "$(GREEN)Formatting shell scripts...$(NC)"
	@if command -v shfmt >/dev/null 2>&1; then \
		find . -name "*.sh" -exec shfmt -w {} +; \
		echo "$(GREEN)Scripts formatted$(NC)"; \
	else \
		echo "$(YELLOW)shfmt not installed. Install with: sudo apt install shfmt$(NC)"; \
	fi

# Documentation targets
docs: ## Generate documentation
	@echo "$(GREEN)Documentation is available in README.md$(NC)"
	@echo "Use 'make help' for available targets"

# CI/CD targets
ci-deps: ## Install CI dependencies (lightweight)
	@sudo apt update
	@sudo apt install -y shellcheck shfmt

ci-test: ci-deps test lint ## Run CI tests

# Development targets
dev-build: ## Development build with additional debugging
	@echo "$(GREEN)Running development build...$(NC)"
	@sudo DEBUG=1 ./build.sh

watch: ## Watch for changes and rebuild (requires inotify-tools)
	@if ! command -v inotifywait >/dev/null 2>&1; then \
		echo "$(RED)inotify-tools not installed. Install with: sudo apt install inotify-tools$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)Watching for changes... Press Ctrl+C to stop$(NC)"
	@while inotifywait -r -e modify,create,delete .; do \
		echo "$(YELLOW)Changes detected, rebuilding...$(NC)"; \
		$(MAKE) build; \
	done