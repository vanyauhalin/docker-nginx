.PHONY: help
help: # Show help information
	@echo "Recipes:"
	@grep --extended-regexp "^[a-z-]+: #" "$(MAKEFILE_LIST)" | \
		awk 'BEGIN {FS = ": # "}; {printf "  %-9s%s\n", $$1, $$2}'

.PHONY: build
build: # Build the Docker image
	@docker build --tag vanyauhalin/nginx .

.PHONY: lint
lint: # Lint the Dockerfile and shell scripts
	@hadolint Dockerfile
	@shellcheck **/*.sh
	@shfmt --diff **/*.sh
