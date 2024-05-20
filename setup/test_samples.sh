#!/bin/sh

set keypath = "keys"

echo "Configure key on current host"
rm -f  ~/.ssh/mptcprootkey
cp $keypath/mptcprootkey ~/.ssh/
chmod 400 ~/.ssh/mptcprootkey


echo "done"
exit 0

ssh -p 3322 -i ~/.ssh/mptcprootkey root@192.168.56.1 