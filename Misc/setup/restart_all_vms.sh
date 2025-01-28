#!/bin/csh


ssh -p 3322 -i ~/.ssh/mptcprootkey root@192.168.56.1 "shutdown -r now" >/dev/null &
ssh -p 3323 -i ~/.ssh/mptcprootkey root@192.168.56.1 "shutdown -r now" >/dev/null &
ssh -p 4422 -i ~/.ssh/mptcprootkey root@192.168.56.1 "shutdown -r now" >/dev/null &
ssh -p 4423 -i ~/.ssh/mptcprootkey root@192.168.56.1 "shutdown -r now" >/dev/null &

echo "done"
exit 0

