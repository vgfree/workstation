#!/bin/bash

sample_text="global variable"

foo() {
	local sample_text="local variable"
	echo $sample_text
}

echo $sample_text

foo

echo $sample_text

exit 0
