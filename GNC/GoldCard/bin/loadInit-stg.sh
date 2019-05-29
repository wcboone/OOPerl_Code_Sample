#!/bin/bash

# $Id: loadInit-stg.sh,v 1.1 2007/01/19 23:15:20 donohuet Exp $

# GNC Gold Card initial load:  on staging, load the 2nd half of the data

/feeds/bin/datax -file=gc_bs -db=feedsprd -legacy -import gnc.goldcard &
/feeds/bin/datax -file=gc_bt -db=feedsprd -legacy -import gnc.goldcard &
wait
/feeds/bin/datax -file=gc_bu -db=feedsprd -legacy -import gnc.goldcard &
/feeds/bin/datax -file=gc_bv -db=feedsprd -legacy -import gnc.goldcard &
wait
/feeds/bin/datax -file=gc_bw -db=feedsprd -legacy -import gnc.goldcard &
/feeds/bin/datax -file=gc_bx -db=feedsprd -legacy -import gnc.goldcard &
wait
/feeds/bin/datax -file=gc_by -db=feedsprd -legacy -import gnc.goldcard &
/feeds/bin/datax -file=gc_bz -db=feedsprd -legacy -import gnc.goldcard &
wait
/feeds/bin/datax -file=gc_ca -db=feedsprd -legacy -import gnc.goldcard &
/feeds/bin/datax -file=gc_cb -db=feedsprd -legacy -import gnc.goldcard &
wait
/feeds/bin/datax -file=gc_cc -db=feedsprd -legacy -import gnc.goldcard &
/feeds/bin/datax -file=gc_cd -db=feedsprd -legacy -import gnc.goldcard &
wait
/feeds/bin/datax -file=gc_ce -db=feedsprd -legacy -import gnc.goldcard &
/feeds/bin/datax -file=gc_cf -db=feedsprd -legacy -import gnc.goldcard &
wait
/feeds/bin/datax -file=gc_cg -db=feedsprd -legacy -import gnc.goldcard &
/feeds/bin/datax -file=gc_ch -db=feedsprd -legacy -import gnc.goldcard &
wait
/feeds/bin/datax -file=gc_ci -db=feedsprd -legacy -import gnc.goldcard &
/feeds/bin/datax -file=gc_cj -db=feedsprd -legacy -import gnc.goldcard &
wait
/feeds/bin/datax -file=gc_ck -db=feedsprd -legacy -import gnc.goldcard &
/feeds/bin/datax -file=gc_cl -db=feedsprd -legacy -import gnc.goldcard &
wait
/feeds/bin/datax -file=gc_cm -db=feedsprd -legacy -import gnc.goldcard &
/feeds/bin/datax -file=gc_cn -db=feedsprd -legacy -import gnc.goldcard &
wait
/feeds/bin/datax -file=gc_co -db=feedsprd -legacy -import gnc.goldcard &
/feeds/bin/datax -file=gc_cp -db=feedsprd -legacy -import gnc.goldcard &
wait
/feeds/bin/datax -file=gc_cq -db=feedsprd -legacy -import gnc.goldcard &
/feeds/bin/datax -file=gc_cr -db=feedsprd -legacy -import gnc.goldcard &
wait
/feeds/bin/datax -file=gc_cs -db=feedsprd -legacy -import gnc.goldcard &
/feeds/bin/datax -file=gc_ct -db=feedsprd -legacy -import gnc.goldcard &
wait
/feeds/bin/datax -file=gc_cu -db=feedsprd -legacy -import gnc.goldcard &
/feeds/bin/datax -file=gc_cv -db=feedsprd -legacy -import gnc.goldcard &
wait
/feeds/bin/datax -file=gc_cw -db=feedsprd -legacy -import gnc.goldcard &
/feeds/bin/datax -file=gc_cx -db=feedsprd -legacy -import gnc.goldcard &
wait
/feeds/bin/datax -file=gc_cy -db=feedsprd -legacy -import gnc.goldcard &
/feeds/bin/datax -file=gc_cz -db=feedsprd -legacy -import gnc.goldcard &
wait
/feeds/bin/datax -file=gc_da -db=feedsprd -legacy -import gnc.goldcard &
/feeds/bin/datax -file=gc_db -db=feedsprd -legacy -import gnc.goldcard &
wait
/feeds/bin/datax -file=gc_dc -db=feedsprd -legacy -import gnc.goldcard &
/feeds/bin/datax -file=gc_dd -db=feedsprd -legacy -import gnc.goldcard &
wait
/feeds/bin/datax -file=gc_de -db=feedsprd -legacy -import gnc.goldcard &
/feeds/bin/datax -file=gc_df -db=feedsprd -legacy -import gnc.goldcard &
wait
/feeds/bin/datax -file=gc_dg -db=feedsprd -legacy -import gnc.goldcard &
/feeds/bin/datax -file=gc_dh -db=feedsprd -legacy -import gnc.goldcard &
wait

# this one was the test case, don't reload...
#/feeds/bin/datax -file=gc_di -db=feedsprd -legacy -import gnc.goldcard &
#wait
