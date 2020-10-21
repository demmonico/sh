#!/bin/bash

#-----------------------------------------------------------#
# @author demmonico <demmonico@gmail.com> <https://github.com/demmonico>#
# @use: ./fix_php7.sh
#-----------------------------------------------------------#




echo "Patching ErrorException ...";
FILENAME='vendor/yiisoft/yii2/base/ErrorException.php';


#sudo sed -i "/^127\.0\.0\.1\s*$domain$/d" /etc/hosts;
#sed  "/^\s*$needle\s*/$mode $inserts" $FILENAME;
#sed  "$lineNumber i $inserts" $FILENAME;


STR='foreach ($trace as $frame) { \/\/';
if ! grep -Fxq "$STR" $FILENAME ; then
    sed -i "47s/^\s/$STR/" $FILENAME;
fi;

STR='$phpCompatibleTrace = [];';
if ! grep -Fxq "$STR" $FILENAME ; then
    sed -i "47i $STR" $FILENAME;
fi;

STR='$phpCompatibleTrace[] = $frame;';
if ! grep -Fxq "$STR" $FILENAME ; then
    sed -i "64i $STR" $FILENAME;
fi;

STR='$ref->setValue($this, $phpCompatibleTrace); \/\/';
if ! grep -Fxq "$STR" $FILENAME ; then
    sed -i "69s/^\s/$STR/" $FILENAME;
fi;


echo "Done";