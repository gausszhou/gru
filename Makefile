.PHONY: build test clean lint fmt vet build-all

BINARY_NAME=gru
BIN_DIR=bin
DIST_DIR=dist
CMD_DIR=.

VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
LDFLAGS = -s -w -X github.com/gausszhou/gru/cmd.version=$(VERSION)

build:
	go build -ldflags="$(LDFLAGS)" -o $(BIN_DIR)/$(BINARY_NAME) $(CMD_DIR)

build-all: build-linux build-darwin build-windows

build-linux:
	mkdir -p $(BIN_DIR) $(DIST_DIR)
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="$(LDFLAGS)" -o $(BIN_DIR)/$(BINARY_NAME)-linux-amd64 $(CMD_DIR)
	CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -ldflags="$(LDFLAGS)" -o $(BIN_DIR)/$(BINARY_NAME)-linux-arm64 $(CMD_DIR)
	cp $(BIN_DIR)/$(BINARY_NAME)-linux-amd64 $(BIN_DIR)/$(BINARY_NAME)
	tar czf $(DIST_DIR)/$(BINARY_NAME)-linux-amd64.tar.gz -C $(BIN_DIR) $(BINARY_NAME)
	rm $(BIN_DIR)/$(BINARY_NAME)
	cp $(BIN_DIR)/$(BINARY_NAME)-linux-arm64 $(BIN_DIR)/$(BINARY_NAME)
	tar czf $(DIST_DIR)/$(BINARY_NAME)-linux-arm64.tar.gz -C $(BIN_DIR) $(BINARY_NAME)
	rm $(BIN_DIR)/$(BINARY_NAME)

build-darwin:
	mkdir -p $(BIN_DIR) $(DIST_DIR)
	CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build -ldflags="$(LDFLAGS)" -o $(BIN_DIR)/$(BINARY_NAME)-darwin-amd64 $(CMD_DIR)
	CGO_ENABLED=0 GOOS=darwin GOARCH=arm64 go build -ldflags="$(LDFLAGS)" -o $(BIN_DIR)/$(BINARY_NAME)-darwin-arm64 $(CMD_DIR)
	cp $(BIN_DIR)/$(BINARY_NAME)-darwin-amd64 $(BIN_DIR)/$(BINARY_NAME)
	tar czf $(DIST_DIR)/$(BINARY_NAME)-darwin-amd64.tar.gz -C $(BIN_DIR) $(BINARY_NAME)
	rm $(BIN_DIR)/$(BINARY_NAME)
	cp $(BIN_DIR)/$(BINARY_NAME)-darwin-arm64 $(BIN_DIR)/$(BINARY_NAME)
	tar czf $(DIST_DIR)/$(BINARY_NAME)-darwin-arm64.tar.gz -C $(BIN_DIR) $(BINARY_NAME)
	rm $(BIN_DIR)/$(BINARY_NAME)

build-windows:
	mkdir -p $(BIN_DIR) $(DIST_DIR)
	CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build -ldflags="$(LDFLAGS)" -o $(BIN_DIR)/$(BINARY_NAME)-windows-amd64.exe $(CMD_DIR)
	CGO_ENABLED=0 GOOS=windows GOARCH=arm64 go build -ldflags="$(LDFLAGS)" -o $(BIN_DIR)/$(BINARY_NAME)-windows-arm64.exe $(CMD_DIR)
	cp $(BIN_DIR)/$(BINARY_NAME)-windows-amd64.exe $(BIN_DIR)/$(BINARY_NAME).exe
	zip -j $(DIST_DIR)/$(BINARY_NAME)-windows-amd64.zip $(BIN_DIR)/$(BINARY_NAME).exe
	rm $(BIN_DIR)/$(BINARY_NAME).exe
	cp $(BIN_DIR)/$(BINARY_NAME)-windows-arm64.exe $(BIN_DIR)/$(BINARY_NAME).exe
	zip -j $(DIST_DIR)/$(BINARY_NAME)-windows-arm64.zip $(BIN_DIR)/$(BINARY_NAME).exe
	rm $(BIN_DIR)/$(BINARY_NAME).exe

test:
	go test ./...

clean:
	rm -rf $(BIN_DIR)
	rm -rf $(DIST_DIR)
	rm -f coverage.out

lint:
	@which golangci-lint >/dev/null 2>&1 || go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	golangci-lint run ./...

fmt:
	go fmt ./...

vet:
	go vet ./...
