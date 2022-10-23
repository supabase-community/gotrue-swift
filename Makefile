PLATFORM_IOS = iOS Simulator,name=iPhone 14 Pro Max
PLATFORM_MACOS = macOS
PLATFORM_MAC_CATALYST = macOS,variant=Mac Catalyst
PLATFORM_TVOS = tvOS Simulator,name=Apple TV
PLATFORM_WATCHOS = watchOS Simulator,name=Apple Watch Series 7 (45mm)

default: test-all

test-all: test-ios test-macos test-tvos

test-library:
	for platform in "$(PLATFORM_IOS)" "$(PLATFORM_MACOS)" "$(PLATFORM_MAC_CATALYST)" "$(PLATFORM_TVOS)" "$(PLATFORM_WATCHOS)"; do \
		xcodebuild test \
			-workspace GoTrue.xcworkspace \
			-scheme GoTrue \
			-destination platform="$$platform" || exit 1; \
	done;

format:
	@swiftformat .

api:
	create-api generate --output Sources/GoTrue/Generated --config .createapi.yml openapi.yaml
	sed -i "" "s/public /internal /g" Sources/GoTrue/Generated/Paths.swift
	$(MAKE) format

.PHONY: format test-all test-library create-api
