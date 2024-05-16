.DEFAULT_GOAL := help
VARIABLE = 1

.PHONY: all
all: # Run all recipes.
all: help

.PHONY: help
help: # Show help information.
	@echo "recipes:"
	@grep --extended-regexp "^[a-z-]+: #" "$(MAKEFILE_LIST)" | \
		awk 'BEGIN {FS = ": # "}; {printf "  %-8s%s\n", $$1, $$2}'
	@echo "\nvariables:"
	@make --dry-run --print-data-base --file $(MAKEFILE_LIST) | \
		awk '/^# (makefile |command)/{getline; if ($$0 !~ /^MAKEFILE_LIST/) print}' | \
		awk 'BEGIN {FS = ":?= "}; {printf "  %-15s%s\n", $$1, $$2}' | sort

.PHONY: build
build: # Build the Docker image.
	@docker build --tag vanyauhalin/nginx .
