# Project information
PROJECT_DIR := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))
BIN_DIR := $(PROJECT_DIR)/bin
## protoc files
THIRD_PARTY_DIR=$(PROJECT_DIR)/third_party
PROTO_FILES=$(shell find $(PROJECT_DIR) -path $(THIRD_PARTY_DIR) -prune -o -name '*.proto' -print)

# Build binary
GOPATH=$(shell go env GOPATH)
GOBIN=$(shell go env GOBIN)

ifeq ($(GOBIN),)
    GOBIN := $(GOPATH)/bin
endif

##@ General

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "Usage:\n  make \033[36m<target>\033[0m\n"} /^[%\/a-zA-Z_._0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
.DEFAULT_GOAL := help

.PHONY: errors reasons

##@ Development
errors: protoc-gen-go ## generate errors.proto
	@find $(PROJECT_DIR) -path $(PROJECT_DIR)/reasons -prune -o -name '*.pb.go' -exec rm -rf {} \;
	@protoc --proto_path=$(PROJECT_DIR) \
		--proto_path=$(THIRD_PARTY_DIR) \
		--go_out=paths=source_relative:$(PROJECT_DIR) \
		errors.proto
.PHONY: reasons

reasons: protoc-gen-go protoc-gen-go-errors ## generate reasons/reasons.proto
	@find $(PROJECT_DIR)/reasons -name '*.pb.go' -exec rm -rf {} \;
	@protoc --proto_path=$(PROJECT_DIR) \
		--proto_path=$(THIRD_PARTY_DIR) \
		--go_out=paths=source_relative:$(PROJECT_DIR) \
		--go-errors_out=paths=source_relative:$(PROJECT_DIR) \
		reasons/reasons.proto

##@ Install
.PHONY: protoc-gen-go
protoc-gen-go: ## Download protoc-gen-go-* plugin to global '$GOPATH/bin' if necessary.
	$(call go-install-tool-global,protoc-gen-go,google.golang.org/protobuf/cmd/protoc-gen-go@v1.36.12)

.PHONY: protoc-gen-go-errors
protoc-gen-go-errors: ## Force download protoc-gen-go-errors plugin to global '$GOPATH/bin' if necessary.
	$(call go-install-tool-global,protoc-gen-go-errors,./cmd/protoc-gen-go-errors,true)

define go-install-tool-global
@if [ "$(3)" = "true" ]; then \
	echo "Force updating $(1)..." ;\
	rm -f $(GOBIN)/$(1)$(BIN_EXT) ;\
fi
@mkdir -p $(GOBIN)
@[ -f $(GOBIN)/$(1)$(BIN_EXT) ] || { \
	set -e ;\
	echo "Downloading $(2) to $(GOBIN)" ;\
	go install $(2) ;\
}
endef
