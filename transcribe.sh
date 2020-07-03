#!/bin/sh
if [ ! -f ./configuration.lua ]
then
    echo "Please insert the required variables into configuration.example.lua. Then, you need to rename configuration.example.lua to configuration.lua!"
else
    cd helpers/
    while true; do
        lua transcribe.lua
        echo "Transcribe helper has stopped!"
        sleep 3s
    done
fi
