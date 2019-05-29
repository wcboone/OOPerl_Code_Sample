#!/bin/bash

# $Id: loadInit-dev.sh,v 1.1 2007/01/19 23:15:19 donohuet Exp $

# GNC Gold Card initial load:  on devel, load the 1st half of the data

/feeds/bin/datax -file=gc_aa -db=feedsprd -legacy -import gnc.goldcard &
/feeds/bin/datax -file=gc_ab -db=feedsprd -legacy -import gnc.goldcard &
wait
/feeds/bin/datax -file=gc_ac -db=feedsprd -legacy -import gnc.goldcard &
/feeds/bin/datax -file=gc_ad -db=feedsprd -legacy -import gnc.goldcard &
wait
/feeds/bin/datax -file=gc_ae -db=feedsprd -legacy -import gnc.goldcard &
/feeds/bin/datax -file=gc_af -db=feedsprd -legacy -import gnc.goldcard &
wait
/feeds/bin/datax -file=gc_ag -db=feedsprd -legacy -import gnc.goldcard &
/feeds/bin/datax -file=gc_ah -db=feedsprd -legacy -import gnc.goldcard &
wait
/feeds/bin/datax -file=gc_ai -db=feedsprd -legacy -import gnc.goldcard &
/feeds/bin/datax -file=gc_aj -db=feedsprd -legacy -import gnc.goldcard &
wait
/feeds/bin/datax -file=gc_ak -db=feedsprd -legacy -import gnc.goldcard &
/feeds/bin/datax -file=gc_al -db=feedsprd -legacy -import gnc.goldcard &
wait
/feeds/bin/datax -file=gc_am -db=feedsprd -legacy -import gnc.goldcard &
/feeds/bin/datax -file=gc_an -db=feedsprd -legacy -import gnc.goldcard &
wait
/feeds/bin/datax -file=gc_ao -db=feedsprd -legacy -import gnc.goldcard &
/feeds/bin/datax -file=gc_ap -db=feedsprd -legacy -import gnc.goldcard &
wait
/feeds/bin/datax -file=gc_aq -db=feedsprd -legacy -import gnc.goldcard &
/feeds/bin/datax -file=gc_ar -db=feedsprd -legacy -import gnc.goldcard &
wait
/feeds/bin/datax -file=gc_as -db=feedsprd -legacy -import gnc.goldcard &
/feeds/bin/datax -file=gc_at -db=feedsprd -legacy -import gnc.goldcard &
wait
/feeds/bin/datax -file=gc_au -db=feedsprd -legacy -import gnc.goldcard &
/feeds/bin/datax -file=gc_av -db=feedsprd -legacy -import gnc.goldcard &
wait
/feeds/bin/datax -file=gc_aw -db=feedsprd -legacy -import gnc.goldcard &
/feeds/bin/datax -file=gc_ax -db=feedsprd -legacy -import gnc.goldcard &
wait
/feeds/bin/datax -file=gc_ay -db=feedsprd -legacy -import gnc.goldcard &
/feeds/bin/datax -file=gc_az -db=feedsprd -legacy -import gnc.goldcard &
wait
/feeds/bin/datax -file=gc_ba -db=feedsprd -legacy -import gnc.goldcard &
/feeds/bin/datax -file=gc_bb -db=feedsprd -legacy -import gnc.goldcard &
wait
/feeds/bin/datax -file=gc_bc -db=feedsprd -legacy -import gnc.goldcard &
/feeds/bin/datax -file=gc_bd -db=feedsprd -legacy -import gnc.goldcard &
wait
/feeds/bin/datax -file=gc_be -db=feedsprd -legacy -import gnc.goldcard &
/feeds/bin/datax -file=gc_bf -db=feedsprd -legacy -import gnc.goldcard &
wait
/feeds/bin/datax -file=gc_bg -db=feedsprd -legacy -import gnc.goldcard &
/feeds/bin/datax -file=gc_bh -db=feedsprd -legacy -import gnc.goldcard &
wait
/feeds/bin/datax -file=gc_bi -db=feedsprd -legacy -import gnc.goldcard &
/feeds/bin/datax -file=gc_bj -db=feedsprd -legacy -import gnc.goldcard &
wait
/feeds/bin/datax -file=gc_bk -db=feedsprd -legacy -import gnc.goldcard &
/feeds/bin/datax -file=gc_bl -db=feedsprd -legacy -import gnc.goldcard &
wait
/feeds/bin/datax -file=gc_bm -db=feedsprd -legacy -import gnc.goldcard &
/feeds/bin/datax -file=gc_bn -db=feedsprd -legacy -import gnc.goldcard &
wait
/feeds/bin/datax -file=gc_bo -db=feedsprd -legacy -import gnc.goldcard &
/feeds/bin/datax -file=gc_bp -db=feedsprd -legacy -import gnc.goldcard &
wait
/feeds/bin/datax -file=gc_bq -db=feedsprd -legacy -import gnc.goldcard &

# this one was the test case, don't reload...
#/feeds/bin/datax -file=gc_br -db=feedsprd -legacy -import gnc.goldcard &
wait
