#!/usr/bin/python3
# same as subse5/devowel
import fileinput, re
for line in fileinput.input():
	line = re.sub(r'[aeiou]', '---', line)
	print(line, end='')
