PLATFORM ?= iOS Simulator,name=iPhone 14 Pro Max

test-library:
	xcodebuild test \
			-scheme GoTrue \
			-destination platform="$(PLATFORM)" || exit 1;
	
build-example:
	xcodebuild build \
		-scheme Examples \
		-destination platform="$(PLATFORM)" || exit 1;

format:
	@swift format -i -r .

.PHONY: test-library build-example format test-library
