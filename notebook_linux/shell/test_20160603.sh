#!/bin/bash

if test -f testDemo_20160603.sh
then
	echo "testDemo_20160603.sh exists."
fi

if [ -f test.c ]
then
	echo "test.c exists."
else
	echo "I cannot find exists."
fi

exit 0
