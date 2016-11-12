#!/usr/bin/env python3
# Credit to @JuanPotato for helping with this script
import sys
from random import random, randint, choice
emojis = ['😂', '😂', '😂', '😂', '👌', '✌', '💞', '👍', '👌', '💯', '🎶', '👀',
		  '😂', '👓', '👏', '👐', '🍕', '💥', '🍴', '💦', '💦', '🍑', '🍆', '😩',
		  '😏', '👉👌', '👀', '👅', '😩']
def copypasta(text):
	split = text.split()
	msg = []
	for word in split:
		msg.append(word)
		if random() > 0.5:
			x = randint(1, 4)
			cancer = ''.join(choice(emojis)
		for i in range(x))
			msg.append(cancer)
	return ' '.join(msg)
query = ' '.join(sys.argv[1:])
output = copypasta(query)
print(output)