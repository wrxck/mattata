# Yay, Python with Lua!

import os
import sys
from bs4 import BeautifulSoup
import demjson
sys.stdout = open(sys.stdout.fileno(), mode='w', encoding='utf8', buffering=1)
def getLyrics(link):
	try:
		page = os.popen('curl ' + link).read()
		soup = BeautifulSoup(page, 'html.parser')
		song = ''
		for textarea in soup.findAll('script'):
			if '__mxmProps' in textarea.text:
				s = textarea.text.replace('var __mxmProps = ', '')
				s = s.replace('{"pageProps":{"pageName":"track"}};var __mxmState = ', '')
				s = s.replace(';', '')
				json_acceptable_string = s.replace('\n', '<br>')
				d = demjson.decode(json_acceptable_string)
				song = d['page']
		if not song:
			int('a')
		return song
	except Exception as e:
		print(e)
		return false
song = getyrics(sys.argv[1])
output = song['lyrics']['lyrics']['body'].replace('<br>', '\n')
print(output)
