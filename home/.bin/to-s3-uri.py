#!/usr/bin/env python

import sys
import re

for url in sys.argv[1:]:
	match = re.search(".*amazonaws.com/(.*)", url)
	if match:
		print('s3://' + match.groups(1)[0].split("?")[0])
	elif "://" not in url:
		print('s3://' + url)



