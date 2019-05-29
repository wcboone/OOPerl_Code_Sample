#!/bin/ksh
#
# QAD utility to account numbers in GNC customer feed export.
#
# $Id: gncCheckAccts.sh,v 1.1 2007/01/19 23:15:18 donohuet Exp $

# GSI account_id numbers:
accounts="971661852 963217591 961526911 972760762 972428752 958954221 956960011 970998952 970999062 970998712 970998942 970892292 970892402 970892592 970892282 970418332 968724912"

# GNC GoldCard exports
#files="GSICustomer200701121836.txt GSICustomer200701181610.txt GSICustomer200701181740.txt GSICustomer200701181829.txt"
files="GSICustomer200701181829.txt"

for a in $accounts ; do
    echo account $a:
    grep $a $files
    echo ===
done
