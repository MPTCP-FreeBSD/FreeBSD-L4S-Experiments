#!/bin/bash

# Run scripts in the specified order and redirect output to terminaloutput.txt
{
  # Run scripts with '1' and 'ecn' first
  csh codel1_ecn.sh
  csh pie1_ecn.sh
  csh fqcodel1_ecn.sh
  csh fqpie1_ecn.sh
  
  # Run scripts with '1' and 'noecn'
  csh codel1_noecn.sh
  csh pie1_noecn.sh
  csh fqcodel1_noecn.sh
  csh fqpie1_noecn.sh
  
  # Run scripts with '2' and 'ecn'
  csh codel2_ecn.sh
  csh pie2_ecn.sh
  csh fqcodel2_ecn.sh
  csh fqpie2_ecn.sh
  
  # Run scripts with '2' and 'noecn'
  csh codel2_noecn.sh
  csh pie2_noecn.sh
  csh fqcodel2_noecn.sh
  csh fqpie2_noecn.sh

} > terminaloutput.txt 2>&1 ;

sudo scp -P 3322 -p -i ~/.ssh/mptcprootkey root@192.168.56.1:*.siftr.log ./datatest1; sudo scp -P 3322 -p -i ~/.ssh/mptcprootkey root@192.168.56.1:*.pcap ./datatest1;sudo scp -P 3322 -p -i ~/.ssh/mptcprootkey root@192.168.56.1:*.out ./datatest1;
sudo scp -P 3323 -p -i ~/.ssh/mptcprootkey root@192.168.56.1:*.siftr.log ./datatest2; sudo scp -P 3323 -p -i ~/.ssh/mptcprootkey root@192.168.56.1:*.pcap ./datatest2;sudo scp -P 3323 -p -i ~/.ssh/mptcprootkey root@192.168.56.1:*.out ./datatest2

# Notify completion
echo "All scripts executed and output saved to terminaloutput.txt"
