#
# Run the GNC Gold Card import steps in sequence.
#
# $Id: 

#
# Export
#

/feeds/bin/datax -export -usequery=1  -db=history -start=yesterday -end=yesterday gnc.goldcard &
sleep 60
/feeds/bin/datax -export -usequery=2  -db=history -start=yesterday -end=yesterday gnc.goldcard &
sleep 60
/feeds/bin/datax -export -usequery=3  -db=history -start=yesterday -end=yesterday gnc.goldcard &
wait

#
#  Clean up /tmp from yesterday
#

rm /tmp/GSICustomer*

#
# ok do the rest of the process
#

/feeds/bin/datax -gather -zip -upload  -db=history -start=today gnc.goldcard
