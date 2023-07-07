PLATFORM ?= iOS Simulator,name=iPhone 14 Pro Max

test-library:
	xcodebuild test \
			-workspace GoTrue.xcworkspace \
			-scheme GoTrue \
			-destination platform="$(PLATFORM)" || exit 1;
	
build-example:
	xcodebuild build \
		-workspace GoTrue.xcworkspace \
		-scheme Examples \
		-destination platform="$(PLATFORM)" || exit 1;

format:
	@swiftformat .

.PHONY: test-library build-example format test-library
