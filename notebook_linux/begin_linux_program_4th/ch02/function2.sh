#!/bin/bash

foo() {
	echo hello;
}

result="$(foo)"
echo "执行"
echo $result

exit 0
