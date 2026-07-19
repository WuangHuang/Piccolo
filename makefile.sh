export PATH="/home/bqhung/Application/oss-cad-suite/bin:$PATH"
clear
iverilog -g2012 -o simv Piccolo_*.sv
vvp simv
rm simv