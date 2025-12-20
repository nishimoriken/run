#!/bin/bash
for x in $(seq  50 50 600)
do
    for y in {2..7}
    do
	X_PAD=$(printf "%03d" $x)
	Y_PAD=$(printf "%02d" $y)
	echo -e "handmade_${X_PAD}_${Y_PAD}\tbenchmark/handmade/handmade_${X_PAD}_${Y_PAD}.bnet\tbenchmark/handmade/handmade_${X_PAD}_${Y_PAD}_01.csv"
    done
done
