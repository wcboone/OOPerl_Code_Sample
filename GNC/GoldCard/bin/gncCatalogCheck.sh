#!/bin/ksh
#
# QAD utility to check catalog request in GNC customer feed export.
#
# Designed to work with the output from fmtExport.sh
#
# $Id: gncCatalogCheck.sh,v 1.1 2007/01/19 23:15:18 donohuet Exp $

grep -A3 -B30 'REASON.*C$' $1 | grep -A8 -B24 'STATE.*:  *$' | grep -c BILL_TO

# should also check FIRST_NAME, LAST_NAME, STREET_ADDRESS, STATE, ZIP_CODE,
# requires changing the "-A8 -B24" for each of those.  Or a perl implementation
# to parse records.
