#!/usr/bin/env python3
"""
Copyright (c) 2016, Paul Buonopane and Brandon Currell
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
"""
from sys import stderr, exit
try:
    from sys import argv
    from random import SystemRandom
    from bcrypt import hashpw, gensalt
    from os import path, urandom
except ImportError as err:
    exit(1)
def _passchars():
    for i in range(0x000020, 0x00007F): yield chr(i)
__urandom_warning = False
def _random(n):
    global __urandom_warning
    if not __urandom_warning:
        try:
            rng = '/dev/urandom'
            if path.exists(rng):
                with open(rng, 'rb') as f:
                    return f.read(n)
        except Exception as err:
            __urandom_warning = True
    return urandom(n)
class RealSystemRandom(SystemRandom):
    def random(self):
        return (int.from_bytes(_random(7), 'big') >> 3) * RECIP_BPF
    def getrandbits(self, k):
        if k <= 0:
            raise ValueError('number of bits must be greater than zero')
        if k != int(k):
            raise TypeError('number of bits should be an integer')
        numbytes = (k + 7) // 8
        x = int.from_bytes(_random(numbytes), 'big')
        return x >> (numbytes * 8 - k)
class PassGen(object): # Based on code by Brandon Currell: https://gist.github.com/BranicYeti/1264f7f60f66d6a065edb20e37259ddd
    def __init__(self):
        self.chars = [c for c in _passchars()]
        self.random = RealSystemRandom()
    def randchar(self):
        index = self.random.randrange(len(self.chars))
        return self.chars[index]
    def generate(self, length):
        password = ''
        while len(password) < length:
            c = self.randchar()
            if (len(password) == 0 or len(password) == length - 1) and c == ' ':
                continue
            password += c
        return password
if __name__ == '__main__':
    try:
        length = 64
        if len(argv) >= 2:
            length = int(argv[1])
        gen = PassGen()
        password = gen.generate(length)
        print(password)
    except KeyboardInterrupt:
        print("Interrupted", file=stderr)