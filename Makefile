test:
	LIBRARY_PATH=$(PWD)/ext crystal spec

.PHONY: test
