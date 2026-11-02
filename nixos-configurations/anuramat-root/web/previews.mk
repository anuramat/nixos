.SILENT:
.PHONY: previews clean

INPUT_DIR := ./photo/fullsize
OUTPUT_DIR := ./photo/preview

INPUT_FILES := $(shell @fd@ . $(INPUT_DIR) -e jpg -e png -e jxl)
OUTPUT_FILES := $(patsubst $(INPUT_DIR)/%, $(OUTPUT_DIR)/%, $(INPUT_FILES))

previews: $(OUTPUT_FILES)
$(OUTPUT_DIR)/%: $(INPUT_DIR)/%
	echo generating preview for "$<"
	mkdir -p $(dir $@)
	@magick@ "$<" -thumbnail 256 "$@"

clean:
	rm -rf $(OUTPUT_DIR)
