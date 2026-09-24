PREFIX ?= $(HOME)/.local

.PHONY: build install test

build:
	swift build -c release --scratch-path .build

install: build
	install -d "$(PREFIX)/bin"
	install -m 755 .build/release/codexp "$(PREFIX)/bin/codexp"
	cp -R .build/release/codexp_codexp.bundle "$(PREFIX)/bin/"

test:
	swift test --scratch-path .build
