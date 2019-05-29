#
# Run the GNC Gold Card import steps in sequence.
# Produce Results for 2 days
#
# $Id: gnc2DayGoldCardExport.sh,v 1.1 2007/08/13 19:19:25 wallacej Exp $ 
#
# vim:ts=4:sw=2:sta:aw:ai:et:sr:nowrap
# ======================================================================
# $Header: /opt/cvsroot/GSI/DataX/GNC/GoldCard/bin/gnc2DayGoldCardExport.sh,v 1.1 2007/08/13 19:19:25 wallacej Exp $
# $Id: gnc2DayGoldCardExport.sh,v 1.1 2007/08/13 19:19:25 wallacej Exp $
# $Author: wallacej $
# $Date: 2007/08/13 19:19:25 $
# $Revision: 1.1 $
#
#   Tag: $Name:  $
#
# ======================================================================
#


#
# Export
#

/feeds/bin/datax -export -usequery=1  -db=history -start="2 days ago" -end=yesterday gnc.goldcard &
sleep 60
/feeds/bin/datax -export -usequery=2  -db=history -start="2 days ago" -end=yesterday gnc.goldcard &
sleep 60
/feeds/bin/datax -export -usequery=3  -db=history -start="2 days ago" -end=yesterday gnc.goldcard &
wait

#
#  Clean up /tmp from yesterday
#

rm /tmp/GSICustomer*

#
# ok do the rest of the process
#

/feeds/bin/datax -gather -zip -upload  -db=history -start=today gnc.goldcard
