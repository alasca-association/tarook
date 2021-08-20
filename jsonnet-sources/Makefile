MANIFEST_DIR=manifests
MANIFEST_LISTING=$(MANIFEST_DIR).files
CONFIG_FILE=config.jsonnet
clean_command=rm -rf -- $(MANIFEST_DIR); mkdir -p -- $(MANIFEST_DIR)

build: $(MANIFEST_LISTING)

clean:
	$(clean_command)

vendor: jsonnetfile.lock.json jsonnetfile.json
	jb install

$(MANIFEST_LISTING): $(CONFIG_FILE) vendor
	$(clean_command)
	../rebuild.sh "$@" -J vendor -m $(MANIFEST_DIR) "$<"

.PHONY: clean vendor
