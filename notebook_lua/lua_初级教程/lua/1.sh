#!/bin/bash - 
#===============================================================================
#
#          FILE: 1.sh
# 
#         USAGE: ./1.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 2015年11月09日 22:21
#      REVISION:  ---
#===============================================================================

gcc $1 -I/usr/local/include/ -L/usr/local/lib/ -L/usr/local/lib/liblua.a  -llua -ldl -lm
