# syncexplorer

## What's this
A litle program to explore the Atari ST video chip.
It enables you to place a 50/60Hz switch or a Hi/Lo switch anywhere on the screen 
(or rather on the top half of the screen, because dumb coding)
By default the switch is off. Press return to activate it.
Use Esc to toggle between Hz (right border) and resolution (left border) switching.
The displayed number gives the number of nops counted from shortly after vbl interrupt.

## to assemble: 

use linux
install vasm
make sy_exp

for your convenience: PRG included

