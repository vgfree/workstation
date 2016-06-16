#!/bin/bash

while [ "$1" != "" ]; do
	echo "$1"
	shift
done

exit 0

# $0 不变, 然后抛弃$1, 后面的参数依次左移, $* $@ $# 也作相应改变
