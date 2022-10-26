PLATFORM_IOS = iOS Simulator,name=iPhone 14 Pro Max
PLATFORM_MACOS = macOS
PLATFORM_MAC_CATALYST = macOS,variant=Mac Catalyst
PLATFORM_TVOS = tvOS Simulator,name=Apple TV
PLATFORM_WATCHOS = watchOS Simulator,name=Apple Watch Series 7 (45mm)

test-library:
	for platform in "$(PLATFORM_IOS)" "$(PLATFORM_MACOS)" "$(PLATFORM_MAC_CATALYST)" "$(PLATFORM_TVOS)" "$(PLATFORM_WATCHOS)"; do \
		xcodebuild test \
			-workspace GoTrue.xcworkspace \
			-scheme GoTrue \
			-destination platform="$$platform" \
			-derivedDataPath .deriveddata || exit 1; \
	done;
	
build-example:
	xcodebuild build \
		-workspace GoTrue.xcworkspace \
		-scheme Examples \
		-destination platform="$(PLATFORM_IOS)" || exit 1;

format:
	@swiftformat .

api:
	create-api generate --output Sources/GoTrue/Generated --config .createapi.yml openapi.yaml
	sed -i "" "s/public /internal /g" Sources/GoTrue/Generated/Paths.swift
	$(MAKE) format

.PHONY: test-library build-example format test-library create-api
