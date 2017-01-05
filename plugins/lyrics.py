import sys, urllib, re # This IS spaghetti code and is NOT an example of my actual ability...
def u(t):
    def a(c):
        return unichr(int(c.group(1)))
    return re.sub('&#(\d+);', a, t)
def r(h, s):
    try:
        _, h = h.split(s, 1)
    except ValueError:
        return
    x = 0
    y = 0
    z = []
    for v in re.compile(r'<(/?)div>?').finditer(h):
        if v.group(1):
            x -= 1
            if x == 0:
                y = v.end()
        else:
            if x == 0:
                z.append(h[y:v.start()])
            x += 1
        if x == -1:
            z.append(h[y:v.start()])
            break
    else:
        return
    return re.compile(r'<[^>]*>').sub('', re.sub(r' +\n', '\n', re.sub(r'\n +', '\n', re.compile(r'<br\s*/?>').sub('\n', re.sub(r'\s+', ' ', u(re.compile(r'<!--.*-->', re.S).sub('', ''.join(z)))))))).strip()
def b(s):
    return urllib.quote(re.sub(r'[\]\}]', ')', re.sub(r'[\[\{]', '(', re.sub(r'\s+', '_', s).replace('<', 'Less_Than').replace('>', 'Greater_Than').replace('#', 'Number_'))))
def k(f, g):
    j = r(urllib.urlopen('http://lyrics.wikia.com/%s:%s' % (b(f), b(g))).read(), '<div class=\'lyricbox\'>')
    if j and 'Unfortunately, we are not licensed' not in j:
        return j
def p(s):
    return urllib.quote(re.sub(r'\s+', '-', s))
def l(f, g):
    j = r(urllib.urlopen('http://www.lyrics.com/%s-lyrics-%s.html' % (p(g), p(f))).read(), '<div id="lyric_space">')
    if j:
        j, _ = j.split('\n---\nLyrics powered by', 1)
        return j
def w(s, d):
    for v in [k, l]:
        if v(f, g):
            return v(f, g)
if __name__ == '__main__':
    f, g = sys.argv[1:]
    print w(f, g)