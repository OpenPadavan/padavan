#!/bin/bash

# Country codes separated by "|" without spaces
#country="FR|BE|NL|RU|UA|BY|KZ|MD|AZ|AM|GE|LY|LT|TM|UZ|EE"
country="RU|UA|BY|KZ|MD|AZ|AM|GE|LY|LT|TM|UZ|EE"

files="geoip geoip6"


for f in $files
do
	test -f $f.full || mv $f $f.full
	grep -E "$country" $f.full >$f
done
