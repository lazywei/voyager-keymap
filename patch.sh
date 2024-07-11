#!/usr/bin/env bash

# Define source and destination directories
SOURCE_DIR="./voyager_attempt-0624_source"
DEST_DIR="./qmk_firmware/keyboards/voyager/keymaps/cwc"

ZIP_FILE="latest_oryx_source.zip"
FOLDER_TO_REMOVE="voyager_attempt-0624_source"

LAYOUT="BRyqO"
output=$(curl --location 'https://oryx.zsa.io/graphql' --header 'Content-Type: application/json' --data '{"query":"query getLayout($hashId: String!, $revisionId: String!, $geometry: String) {layout(hashId: $hashId, geometry: $geometry, revisionId: $revisionId) {  revision { title, hashId  }}}","variables":{"hashId":"'"$LAYOUT"'","geometry":"voyager","revisionId":"latest"}}' | jq '.data.layout.revision | [.title, .hashId]')

echo "OUTPUT: $output"
TITLE=$(echo "$output" | jq -r '.[0]')
HASH_ID=$(echo "$output" | jq -r '.[1]')

echo "Latest title: $TITLE"
echo "Latest hash: $HASH_ID"

curl -L "https://oryx.zsa.io/source/$HASH_ID" -o "$ZIP_FILE"

# Remove the existing folder
if [ -d "$FOLDER_TO_REMOVE" ]; then
	rm -rf "$FOLDER_TO_REMOVE"
	echo "Removed existing folder: $FOLDER_TO_REMOVE"
fi

# Unzip the specific folder
if [ -f "$ZIP_FILE" ]; then
	unzip "$ZIP_FILE" "voyager_attempt-0624_source/*" -d ./
	echo "Unzipped folder: voyager_attempt-0624_source"
	rm "$ZIP_FILE"
	echo "Removed zip file: $ZIP_FILE"
else
	echo "Zip file not found: $ZIP_FILE"
	exit 1
fi

# Define the files to be copied
FILES=("keymap.c" "rules.mk" "config.h")

# Copy the files and perform the specified updates
for FILE in "${FILES[@]}"; do
	cp "${SOURCE_DIR}/${FILE}" "${DEST_DIR}/"

	if [[ "${FILE}" == "config.h" ]]; then
		echo "#define ACHORDION_STREAK" >>"${DEST_DIR}/${FILE}"
	elif [[ "${FILE}" == "rules.mk" ]]; then
		echo "SRC += features/achordion.c" >>"${DEST_DIR}/${FILE}"
	elif [[ "${FILE}" == "keymap.c" ]]; then
		# Insert the line after the specified line
		awk '/bool process_record_user\(uint16_t keycode, keyrecord_t \*record\) \{/ {print; print "  if (!process_achordion(keycode, record)) { return false; }"; next}1' "${DEST_DIR}/${FILE}" >"${DEST_DIR}/${FILE}.tmp" && mv "${DEST_DIR}/${FILE}.tmp" "${DEST_DIR}/${FILE}"
		# Insert #include "cwc.h" after #include "version.h"
		awk '/#include "version.h"/ {print; print "#include \"cwc.c\""; next}1' "${DEST_DIR}/${FILE}" >"${DEST_DIR}/${FILE}.tmp" && mv "${DEST_DIR}/${FILE}.tmp" "${DEST_DIR}/${FILE}"
	fi
done

# Change to the qmk_firmware directory and run make command
cd ./qmk_firmware
make voyager:cwc

echo "Files copied, updated, and build executed successfully."
