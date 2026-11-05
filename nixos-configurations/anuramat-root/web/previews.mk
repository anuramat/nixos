.SILENT:
.PHONY: previews clean

INPUT_DIR := ./photo/fullsize
PREVIEW_DIR := ./photo/preview
MEDIUM_DIR := ./photo/medium

INPUT_FILES := $(shell @fd@ . $(INPUT_DIR) -e jpg -e png -e jxl)
PREVIEW_FILES := $(patsubst $(INPUT_DIR)/%, $(PREVIEW_DIR)/%, $(INPUT_FILES))
MEDIUM_FILES := $(patsubst $(INPUT_DIR)/%, $(MEDIUM_DIR)/%, $(INPUT_FILES))

previews: $(PREVIEW_FILES) $(MEDIUM_FILES)
$(PREVIEW_DIR)/%: $(INPUT_DIR)/%
	echo generating preview for "$<"
	mkdir -p $(dir $@)
	@magick@ "$<" -auto-orient -thumbnail 256 "$@"
$(MEDIUM_DIR)/%: $(INPUT_DIR)/%
	echo generating medium size for "$<"
	mkdir -p $(dir $@)
	@magick@ "$<" -auto-orient -resize '1600x1600>' -quality 85 "$@"

clean:
	rm -rf $(PREVIEW_DIR) $(MEDIUM_DIR)
