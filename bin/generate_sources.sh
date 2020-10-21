#!/usr/bin/env bash

#-----------------------------------------------------------#
#
# Update PO files with source domain texts based on *.files and generate MO files
#
# @author demmonico <demmonico@gmail.com> <https://github.com/demmonico>
# @date 22 Jul 2017
# @package: https://github.com/demmonico/sh
# @package-moved-from: https://github.com/demmonico/bash
#
# @use: ./generate_sources.sh
#-----------------------------------------------------------#

echo "";
echo "Indexing sources ... ";

# get current dir
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# get locale dir
LOCALE_DIR="$(dirname "$DIR")"
# get app root dir
APP_DIR="$(dirname "$LOCALE_DIR")"
# set directory for scan
SCAN_DIR="$APP_DIR/app/views"
# set directory to save generated PO
OUTPUT_DIR="$LOCALE_DIR/en_US.utf-8/LC_MESSAGES"
test -d "$OUTPUT_DIR" || mkdir -p "$OUTPUT_DIR"

# get files with sources
FILES="$DIR/*.files"

# processing files
echo "Scanning text sources ..."
for FILE in $FILES
do
  echo "Processing file $FILE ..."

  # get filename and domain name
  OUTPUT_FILENAME=$(basename "$FILE")
  DOMAIN_NAME="${OUTPUT_FILENAME%.*}"
  OUTPUT_PO_FILE="$OUTPUT_DIR/$DOMAIN_NAME.po"
  OUTPUT_MO_FILE="$OUTPUT_DIR/$DOMAIN_NAME.mo"

  # generate PO file
  FUNC_NAME="_$DOMAIN_NAME"
  FUNC_NAMES=""_$DOMAIN_NAME"s"
  #xgettext --files-from=$FILE --output=$OUTPUT_PO_FILE --language=PHP --from-code=UTF-8 -k --keyword=$FUNC_NAME:1 --keyword=$FUNC_NAMES:1,2 -d $OUTPUT_FILENAME;
  find $SCAN_DIR -iname "*.php" | xargs xgettext --output=$OUTPUT_PO_FILE --language=PHP --from-code=UTF-8 --no-wrap -k --keyword=$FUNC_NAME:1 --keyword=$FUNC_NAMES:1,2;

  # FIX replace charset=CHARSET to charset=UTF-8
  sed -i -E 's/(.*charset=)CHARSET(.*)/\1UTF-8\2/' $OUTPUT_PO_FILE

  # generate MO file
  msgfmt $OUTPUT_PO_FILE -o $OUTPUT_MO_FILE

done

echo "All done. Have a nice day :)";
echo "";

