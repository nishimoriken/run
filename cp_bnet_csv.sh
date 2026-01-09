#!/bin/bash
for x in $(seq  650 50 1000)
do
    for y in {3..7}
    do
        Y_PAD=$(printf "%02d" $y)
    	cp "$HOME/Desktop/bn4rust/benchmark/handmade/handmade_${x}_${Y_PAD}"* ./benchmark/handmade/
    done
done
echo "Done"
