#!/opt/Xilinx/14.7/ISE_DS/ISE/bin/lin/xtclsh
project open $argv
project clean
project close
project open $argv
process run "Generate Programming File"
project close
exit

