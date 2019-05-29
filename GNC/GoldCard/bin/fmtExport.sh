#!/bin/bash

# should be called gncfmtexport.sh

# $Id: fmtExport.sh,v 1.2 2007/01/19 23:12:38 donohuet Exp $

IAM=$(basename $0)
FILE="$1"

DIR="/feeds/data/gnc/gold_card/export"

HDR="/feeds/perl/lib/GSI/DataX/GNC/GoldCard/doc/gncHeader.txt"

if [ "$FILE" != "-" ] ; then
    file="$FILE"
    if [ ! -s "$FILE" ] ; then
	USAGE=USAGE
    else
	file="$DIR/$FILE"
	if [ ! -s "$file" ] ; then
	    USAGE=USAGE
	fi
    fi
fi

if [ "$USAGE" ] ; then
    echo usage:  $IAM GSICustomerYYYYMMDDHHMM.txt
    echo
    echo For example:  $IAM GSICustomer200512022012.txt
    exit 1
fi


cat $HDR $file | /feeds/bin/fmtcsv
