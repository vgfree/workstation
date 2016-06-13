#!/bin/bash

rm -f fred

if [ -d fred ]; then
	:
else
	echo file fred did not exist
fi

exit 0
