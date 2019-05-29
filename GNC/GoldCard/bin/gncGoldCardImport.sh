#
# Run the GNC Gold Card import steps in sequence.
#
# $Id: gncGoldCardImport.sh,v 1.8 2008/03/27 12:36:39 wallacej Exp $

dir=/feeds/data/gnc/gold_card
DB='-db=prodfeeds'      # prodfeeds = trans1a, feedstrans1b => trans1b

WHEN=""
[ -n "$1" ] && WHEN="-start=$1"

# Download and Unzip
#
/feeds/bin/datax $WHEN -download -unzip gnc.goldcard

#
# Ticket 67228 - step 0 must complete before executing other steps
#

/feeds/bin/datax $DB $WHEN -import -step=0 gnc.goldcard &
wait

# Import
#
for step in 1 3 ; do
    /feeds/bin/datax $DB $WHEN -import -step=$step gnc.goldcard &
    sleep 120
    nstep=$(( $step + 1 ))
    /feeds/bin/datax $DB $WHEN -import -step=$nstep gnc.goldcard &
    wait
done

/feeds/bin/datax $DB $WHEN -import -step=5 gnc.goldcard &
wait
