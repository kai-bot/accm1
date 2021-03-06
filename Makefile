.PHONY: all clean update-prepare update test-update test-unit test-lint test-lint-prepare image
.DELETE_ON_ERROR:

SHELL=/bin/bash -o pipefail
BIN_DIR=bin
PKG_CONFIG=.pkg_config
PKG_CONFIG_CONTENT=$(shell cat $(PKG_CONFIG))
TEST_RESULTS_DIR=testResults
# TODO: fix code and enable more options
# -E deadcode -E gocyclo -E vetshadow -E gas -E ineffassign
GOMETALINTER_OPTION=--tests --disable-all -E gofmt -E vet -E golint

all: $(BIN_DIR)/azure-cloud-controller-manager

clean:
	rm -rf $(BIN_DIR) $(PKG_CONFIG) $(TEST_RESULTS_DIR)

$(BIN_DIR)/azure-cloud-controller-manager: $(PKG_CONFIG) main.go $(wildcard pkg/**/*)
	 go build -o $@ $(PKG_CONFIG_CONTENT)

image:
	docker build -t $(shell scripts/image-tag.sh) .

$(PKG_CONFIG):
	scripts/pkg-config.sh > $@

test-unit: $(PKG_CONFIG)
	mkdir -p $(TEST_RESULTS_DIR)
	cd pkg && go test $(PKG_CONFIG_CONTENT) -v ./... | tee ../$(TEST_RESULTS_DIR)/unittest.txt
ifdef JUNIT
	scripts/convert-test-report.pl $(TEST_RESULTS_DIR)/unittest.txt > $(TEST_RESULTS_DIR)/unittest.xml
endif

test-lint-prepare:
	go get -u gopkg.in/alecthomas/gometalinter.v1
	gometalinter.v1 -i
test-lint:
	gometalinter.v1 $(GOMETALINTER_OPTION) ./ pkg/...

update-prepare:
	go get -u github.com/sgotti/glide-vc
	go get -u github.com/Masterminds/glide
update:
	scripts/update-dependencies.sh
test-update: update-prepare update
	git checkout glide.lock
	git add -A .
	git diff --staged --name-status --exit-code || { \
		echo "You have committed changes after running 'make update', please check"; \
		exit 1; \
	} \
