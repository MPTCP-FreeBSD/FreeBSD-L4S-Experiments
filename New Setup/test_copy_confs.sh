#!/bin/csh
#
# Copy the config files onto each VM, 
#
# Assumes private/public keys have been copied already, is executed on the
# VM Host machine

scp -P 3322 -p -i ~/.ssh/mptcprootkey confs/client1-confs/rc.conf root@192.168.56.1:/etc/
scp -P 3322 -p -i ~/.ssh/mptcprootkey confs/client1-confs/ipfw.rules root@192.168.56.1:/etc/
scp -P 3322 -p -i ~/.ssh/mptcprootkey confs/client1-confs/loader.conf root@192.168.56.1:/boot/



scp -P 3323 -p -i ~/.ssh/mptcprootkey confs/client2-confs/rc.conf root@192.168.56.1:/etc/
scp -P 3323 -p -i ~/.ssh/mptcprootkey confs/client2-confs/ipfw.rules root@192.168.56.1:/etc/
scp -P 3323 -p -i ~/.ssh/mptcprootkey confs/client2-confs/loader.conf root@192.168.56.1:/boot/



scp -P 4422 -p -i ~/.ssh/mptcprootkey confs/router-confs/rc.conf root@192.168.56.1:/etc/
scp -P 4422 -p -i ~/.ssh/mptcprootkey confs/router-confs/ipfw.rules root@192.168.56.1:/etc/
scp -P 4422 -p -i ~/.ssh/mptcprootkey confs/router-confs/loader.conf root@192.168.56.1:/boot/


scp -P 4423 -p -i ~/.ssh/mptcprootkey confs/server-confs/rc.conf root@192.168.56.1:/etc/
scp -P 4423 -p -i ~/.ssh/mptcprootkey confs/server-confs/ipfw.rules root@192.168.56.1:/etc/
scp -P 4423 -p -i ~/.ssh/mptcprootkey confs/server-confs/loader.conf root@192.168.56.1:/boot/



echo "done"
exit 0



