PROFILE ?= qwen38
PROVIDER ?= lmstudio

.PHONY: install list test

install:
	python3 bin/codex-profile install $(PROFILE) --provider $(PROVIDER)

list:
	python3 bin/codex-profile list

test:
	python3 -m unittest discover -s tests
