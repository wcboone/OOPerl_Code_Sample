#!/bin/bash

# $Id: loadInitial.sh,v 1.1 2007/01/19 23:15:20 donohuet Exp $

# Run this from cron every 2.5 hours to launch 2 loads.


cd /feeds/tmp/GNC
mkdir -p LOAD DONE

loadfile() {
    file=$1
    mv $file LOAD
    f=LOAD/$file
    nohup /feeds/bin/datax -file=$f -db=feedsprd -legacy -import gnc.goldcard
    mv $f DONE
}

for i in 1 2 ; do
    file=$( ls -1 gc_?? | head -1 )
    [ -z "$file" ]   && echo No more files in $DIR	      && exit 1
    [ ! -s "$file" ] && echo File \"$file\" not valid in $DIR && exit 1

    loadfile $file &
done

exit 0
