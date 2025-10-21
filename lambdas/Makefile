AWS_REGION ?= eu-central-1
GOOS=linux
GOARCH=amd64
CGO_ENABLED=0

build-cleanup:
	cd ebook-media-cleanup && GOOS=$(GOOS) GOARCH=$(GOARCH) CGO_ENABLED=$(CGO_ENABLED) go build -tags lambda.norpc -o bootstrap . && mkdir -p dist && zip -j dist/cleanup.zip bootstrap && rm -f bootstrap

build-audit:
	cd ebook-media-audit && GOOS=$(GOOS) GOARCH=$(GOARCH) CGO_ENABLED=$(CGO_ENABLED) go build -tags lambda.norpc -o bootstrap . && mkdir -p dist && zip -j dist/audit.zip bootstrap && rm -f bootstrap

build-auth:
	cd auth-cleanup && GOOS=$(GOOS) GOARCH=$(GOARCH) CGO_ENABLED=$(CGO_ENABLED) go build -o auth-cleanup-lambda .

build-all: build-cleanup build-audit build-auth

.PHONY: build-cleanup build-audit build-auth build-all

