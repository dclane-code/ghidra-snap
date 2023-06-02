#!/bin/bash
sed '/# Launch Ghidra/a if [ ! -d "$HOME/.ghidra" ]; then yad --title "snap connection required" --text "Please run:\n\nsnap connect ghidra-dcl:dot-ghidra" --button:Understood:1; fi' ghidraRun 

