#!/bin/bash


docker save $(docker images -q) -o ./mydockersimages.tar


docker images | sed '1d' | awk '{print $1 " " $2 " " $3}' > mydockersimages.list
~                                                                                  
