#!/bin/bash

echo "Is it moring? please answer yes or no."
read timeofday

if [ "$timeofday" = "yes" ]
then
	echo "Good Moring."
elif [ "$timeofday" = "no" ]
then
	echo "Good afternoon."
else
	echo "Sorry, $timeofday not recognized. Enter yes or no."
	exit 1
fi

exit 0
