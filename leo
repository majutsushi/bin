#!/usr/bin/env python
# Author: Jan Larres <jan@majutsushi.net>
# License: MIT/X11

import curses
import urllib
import urllib2
import sys
import re
from lxml import etree

def process(s):
    s = re.sub(r'<b>',       bold, s)
    s = re.sub(r'</b>',      sgr0, s)
    s = re.sub(r'<i>',       sitm, s)
    s = re.sub(r'</i>',      ritm, s)
    s = re.sub(r'<small>',   '',   s)
    s = re.sub(r'</small>',  '',   s)
    s = re.sub(r'<sup>',     '<',  s)
    s = re.sub(r'</sup>',    '>',  s)
    s = re.sub(r'<sub>',     '',   s)
    s = re.sub(r'</sub>',    '',   s)
    s = re.sub(r'<a[^>]*?>', '',   s)
    s = re.sub(r'</a>',      '',   s)
    s = re.sub(r'<m>',       '',   s)
    s = re.sub(r'</m>',      '',   s)
    s = re.sub(r'<t[^>]*?>', '',   s)
    s = re.sub(r'</t>',      '',   s)
    s = re.sub(r'<sr[^>]*?>', '',  s)
    s = re.sub(r'</sr>',      '',  s)
    # s = re.sub(r'<[^>]+?>', '', s)
    s = re.sub(r'\xa0',      '',   s)
    s = re.sub(r'&#160;', '', s)
    s = re.sub(r'&nbsp;', '', s)
    s = re.sub(r'\*\)$', '', s)
    return s

def getrepr(node):
    repr = node.find('repr')
    word = unicode(repr.text if repr.text else '')
    for child in repr.iterchildren():
        word += etree.tostring(child, encoding=unicode)
    return word

def header(text):
    return '\n' + rev + text + sgr0

def subheader(text):
    return smul + text + rmul

sgr0 = ''
bold = ''
rev = ''
sitm = ''
ritm = ''
smul = ''
rmul = ''

if sys.stdout.isatty():
    curses.setupterm()
    sgr0 = curses.tigetstr('sgr0')
    bold = curses.tigetstr('bold')
    rev  = curses.tigetstr('rev')
    sitm = curses.tigetstr('sitm')
    ritm = curses.tigetstr('ritm')
    smul = curses.tigetstr('smul')
    rmul = curses.tigetstr('rmul')

if len(sys.argv) == 1:
    print 'Usage: leo <words>'
    exit()

words = ' '.join(sys.argv[1:])

print 'Searching for "' + words + '" ...'

params = {'tolerMode'           : 'nof',
          'lp'                  : 'ende', # english-deutsch
          'lang'                : 'en',
          'rmWords'             : 'off',
          'rmSearch'            : 'on',
          'directN'             : '0',
          'search'              : words,
          'searchLoc'           : '0',
          'resultOrder'         : 'basic',
          'multiwordShowSingle' : 'on',
          'sectLenMax'          : '16'}

url = 'http://pda.leo.org/dictQuery/m-vocab/ende/query.xml' + '?' + urllib.urlencode(params)

user_agent = 'Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:15.0) Gecko/20100101 Firefox/15.0.1'
headers = {'User-Agent' : user_agent}

request = urllib2.Request(url, headers=headers)
response = urllib2.urlopen(request)
content = response.read()

results = etree.fromstring(content)

sections = results.find('sectionlist')
for section in sections:
    print header(section.get('sctTitle'))
    for entry in section.findall('entry'):
        wordl = process(getrepr(entry[0]))
        wordr = process(getrepr(entry[1]))

        esclen = 0
        for escseq in [bold, sgr0, sitm, ritm]:
            l = re.findall(re.escape(escseq), wordl)
            esclen += len(l) * len(escseq)

        print u'{0: <{width}} {1}'.format(wordl, wordr, width=39 + esclen)

similar = results.find('similar')
if similar is not None:
    similardict = {}
    for side in similar:
        if side.find('word') is None:
            continue
        words = []
        for word in side:
            words.append(word.text)
        similardict[side.get('lang')] = words
    if len(similardict.keys()) > 0:
        print header('Orthographically similar words')
        for key, val in similardict.items():
            print subheader(key)
            print ' '.join(val)

baseforms = results.find('baseform')
if baseforms is not None:
    basedict = {}
    for side in baseforms:
        if side.find('baselist') is None:
            continue
        words = []
        for base in side.find('baselist'):
            words.append(base.text)
        basedict[side.get('lang')] = words
    if len(basedict.keys()) > 0:
        print header('Potential base forms')
        for key, val in basedict.items():
            print subheader(key)
            print ' '.join(val)

if len(sections) == 0 and similar is None and baseforms is None:
    print 'No results found.'
    exit()
