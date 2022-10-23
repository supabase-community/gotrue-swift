PLATFORM_IOS = iOS Simulator,name=iPhone 11 Pro Max
PLATFORM_MACOS = macOS
PLATFORM_TVOS = tvOS Simulator,name=Apple TV 4K (at 1080p) (2nd generation)

default: test-all

test-all: test-ios test-macos test-tvos

test-ios:
	xcodebuild test \
		-scheme GoTrue \
		-destination platform="$(PLATFORM_IOS)"

test-macos:
	xcodebuild test \
		-scheme GoTrue \
		-destination platform="$(PLATFORM_MACOS)"

test-tvos:
	xcodebuild test \
		-scheme GoTrue \
		-destination platform="$(PLATFORM_TVOS)"

format:
	@swiftformat .

api:
	create-api generate --output Sources/GoTrue/Generated --config .createapi.yml openapi.yaml
	sed -i "" "s/public /internal /g" Sources/GoTrue/Generated/Paths.swift
	$(MAKE) format

.PHONY: format test-all test-ios test-macos test-tvos create-api
