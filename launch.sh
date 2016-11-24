#!/bin/sh
if [ ! -f ./configuration.lua ]
then
	echo "[mattata] Please insert the required variables into configuration.example.lua."
    echo "[mattata] Then, you need to rename configuration.example.lua to configuration.lua!"
else
	while true; do
		lua -e "require('mattata').run({}, require('configuration'))"
		echo '[mattata] Your instance of mattata has been stopped.'
		sleep 3s
	done
fi