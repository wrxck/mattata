#!/bin/sh
if [ ! -f ./configuration.lua ]
then
	echo "Please insert the required variables into configuration.example.lua."
    echo "Then, you need to rename configuration.example.lua to configuration.lua!"
else
	while true; do
		lua -e "require('mattata').run({}, require('configuration'))"
		echo 'mattata has stopped.'
		sleep 3s
	done
fi