#!/bin/ksh
#
# $Id: 3.sh,v 1.1 2007/01/19 23:17:14 donohuet Exp $

for q in 1 2 3 ; do
    /home/donohuet/GSI/bin/myx -verbose=2 -usequery=$q -db=history \
	-start=12/18/2006 -end=yesterday -export gnc.goldcard &
    sleep 60
done
