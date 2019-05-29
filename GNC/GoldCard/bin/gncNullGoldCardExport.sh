#
# Run the GNC Gold Card import steps in sequence.
# Produce Null Results
#
# $Id: gncNullGoldCardExport.sh,v 1.2 2008/12/23 17:17:09 feeds Exp $ 
#
# vim:ts=4:sw=2:sta:aw:ai:et:sr:nowrap
# ======================================================================
# $Header: /opt/cvsroot/GSI/DataX/GNC/GoldCard/bin/gncNullGoldCardExport.sh,v 1.2 2008/12/23 17:17:09 feeds Exp $
# $Id: gncNullGoldCardExport.sh,v 1.2 2008/12/23 17:17:09 feeds Exp $
# $Author: feeds $
# $Date: 2008/12/23 17:17:09 $
# $Revision: 1.2 $
#
#   Tag: $Name:  $
#
# ======================================================================
#


#
# Export
#

/feeds/bin/datax -export -usequery=1  -db=history -start=tomorrow -end=tomorrow gnc.goldcard &
sleep 60
/feeds/bin/datax -export -usequery=2  -db=history -start=tomorrow -end=tomorrow gnc.goldcard &
sleep 60
/feeds/bin/datax -export -usequery=3  -db=history -start=tomorrow -end=tomorrow gnc.goldcard &
wait

#
#  Clean up /tmp from tomorrow
#

rm /tmp/GSICustomer*

#
# ok do the rest of the process
#

sleep 90

/feeds/bin/datax -gather -zip -upload  -db=history -start=today gnc.goldcard
