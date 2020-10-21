#!/usr/bin/env bash

#-----------------------------------------------------------#
#
# Generate PO files with source domain texts based on *.files and generate MO files for pointed files with test
#
# @author: demmonico <demmonico@gmail.com> <https://github.com/demmonico>
# @date: 22 Jul 2017
# @package: https://github.com/demmonico/sh
# @package-moved-from: https://github.com/demmonico/bash
#
# @use: ./generate_test_sources.sh [PARAMS]
# @params:
# -j|--join flag whether need to append text sources to exists. Use it when need to generate sources for several files
# -a|--all  flag whether need to scan all *.php files for text sources. Use it when need to test all sources. Required if -a param not set
# -f|--file [TEXT_SOURCE_FILENAME] (required if -a param not set)
# -l|--language [TEST_LANGUAGE] language to which be copied original to further testing. For example fr_CA
#-----------------------------------------------------------#

# get params and options
isAppendToExists=""
while [[ $# -gt 0 ]]
do
    key="$1"
    case $key in
        -j|--join) isAppendToExists="--join-existing";;
        -a|--all) isScanAll='true';;
        -f|--file)
            if [ ! -z "$2" ]; then
                export SOURCE_FILE="$2"
            fi
            shift
            ;;
        -l|--language)
            if [ ! -z "$2" ]; then
                export TEST_LANGUAGE="$2"
            fi
            shift
            ;;
        *)
            echo "Invalid option -$1"
            break
            ;;
    esac
    shift
done

# validate
if [[ -z "$SOURCE_FILE" ]] && [[ -z "$isScanAll" ]]
then
    echo "Text source filename cannot be empty" 1>&2;
    exit 1;
fi;

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



# create backups
# get files with sources
FILES_BACKUP="$OUTPUT_DIR/*.*"
echo -ne "Backup origin files ..."
for FILE in $FILES_BACKUP
do
    [ -f "$FILE" ] || continue
    [ "${FILE##*.}" != "bak" ] && cp "$FILE" "$FILE.bak"
done
echo " Done"



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
    if [ -z "$isScanAll" ];
    then
        xgettext --output=$OUTPUT_PO_FILE --language=PHP --from-code=UTF-8 --no-wrap $isAppendToExists --msgstr-prefix=_EN_ -k --keyword=$FUNC_NAME:1 --keyword=$FUNC_NAMES:1,2 $SOURCE_FILE;
    else
        find $SCAN_DIR -iname "*.php" | xargs xgettext --output=$OUTPUT_PO_FILE --language=PHP --from-code=UTF-8 --no-wrap --msgstr-prefix=_EN_ -k --keyword=$FUNC_NAME:1 --keyword=$FUNC_NAMES:1,2;
    fi;

    # FIX replace charset=CHARSET to charset=UTF-8
    sed -i -E 's/(.*charset=)CHARSET(.*)/\1UTF-8\2/' $OUTPUT_PO_FILE

    # generate MO file
    msgfmt $OUTPUT_PO_FILE -o $OUTPUT_MO_FILE
done
echo "Scanning was finished successfully"



# copying files to another language for example fr_CA
if [ ! -z "$TEST_LANGUAGE" ];
then

    # set directory to save generated PO
    TEST_OUTPUT_DIR="$LOCALE_DIR/$TEST_LANGUAGE.utf-8/LC_MESSAGES"
    test -d "$TEST_OUTPUT_DIR" || mkdir -p "$TEST_OUTPUT_DIR"

    # get origin files with sources
    FILES="$OUTPUT_DIR/*.po"

    echo -ne "Copying to test translation ..."
    for FILE in $FILES
    do
        OUTPUT_FILENAME=$(basename "$FILE")
        DOMAIN_NAME="${OUTPUT_FILENAME%.*}"
        OUTPUT_PO_FILE="$TEST_OUTPUT_DIR/$DOMAIN_NAME.po"
        OUTPUT_MO_FILE="$TEST_OUTPUT_DIR/$DOMAIN_NAME.mo"
        cp "$FILE" "$OUTPUT_PO_FILE"

        # replace _EN_ prefix to _$LANGUAGE_
        SUFFIX="_${TEST_LANGUAGE#*_}_"
        sed -i -E "s/_EN_/$SUFFIX/" $OUTPUT_PO_FILE

        # re-generate MO file
        msgfmt $OUTPUT_PO_FILE -o $OUTPUT_MO_FILE
    done
    echo " Done"

    echo "All done. Have a nice day :)";
    echo "";

fi
