#!/usr/bin/env python3
# Author: Jan Larres <jan@majutsushi.net>
# License: MIT/X11

import curses
from urllib.parse import urlencode
import sys
import re

import requests
from lxml import etree


sgr0 = ""
bold = ""
rev = ""
sitm = ""
ritm = ""
smul = ""
rmul = ""

colwidth = 39

if sys.stdout.isatty():
    curses.setupterm()
    sgr0 = curses.tigetstr("sgr0").decode(sys.stdout.encoding)
    bold = curses.tigetstr("bold").decode(sys.stdout.encoding)
    rev = curses.tigetstr("rev").decode(sys.stdout.encoding)
    sitm = curses.tigetstr("sitm").decode(sys.stdout.encoding)
    ritm = curses.tigetstr("ritm").decode(sys.stdout.encoding)
    smul = curses.tigetstr("smul").decode(sys.stdout.encoding)
    rmul = curses.tigetstr("rmul").decode(sys.stdout.encoding)
    colwidth = min(curses.tigetnum("cols") // 2, 60)


def process(s: str) -> str:
    s = re.sub(r"<b>", bold, s)
    s = re.sub(r"</b>", sgr0, s)
    s = re.sub(r"<i>", sitm, s)
    s = re.sub(r"</i>", ritm, s)
    s = re.sub(r"<small>", "", s)
    s = re.sub(r"</small>", "", s)
    s = re.sub(r"<sup>", "<", s)
    s = re.sub(r"</sup>", ">", s)
    s = re.sub(r"<sub>", "", s)
    s = re.sub(r"</sub>", "", s)
    s = re.sub(r"<a[^>]*?>", "", s)
    s = re.sub(r"</a>", "", s)
    s = re.sub(r"<m>", "", s)
    s = re.sub(r"</m>", "", s)
    s = re.sub(r"<t[^>]*?>", "", s)
    s = re.sub(r"</t>", "", s)
    s = re.sub(r"<sr[^>]*?>", "", s)
    s = re.sub(r"</sr>", "", s)
    # s = re.sub(r'<[^>]+?>', '', s)
    s = re.sub(r"\xa0", "", s)
    s = re.sub(r"&#160;", "", s)
    s = re.sub(r"&nbsp;", "", s)
    s = re.sub(r"\*\)$", "", s)
    s = re.sub(r"</?flecttabref>", "", s)
    s = re.sub(r"</?domain>", "", s)
    return s


def getrepr(node: etree.Element) -> str:
    node_repr = node.find("repr")
    word: str = node_repr.text if node_repr.text else ""
    for child in node_repr.iterchildren():
        word += etree.tostring(child, encoding=str)
    return word


def header(text: str) -> str:
    return "\n" + rev + text + sgr0


def subheader(text: str) -> str:
    return smul + text + rmul


def main() -> None:
    if len(sys.argv) == 1:
        print("Usage: leo <words>")
        exit()

    search_words = " ".join(sys.argv[1:])

    print('Searching for "' + search_words + '" ...')

    params = {
        "tolerMode": "nof",
        "lp": "ende",  # english-deutsch
        "lang": "en",
        "rmWords": "off",
        "rmSearch": "on",
        "directN": "0",
        "search": search_words,
        "searchLoc": "0",
        "resultOrder": "basic",
        "multiwordShowSingle": "on",
        "sectLenMax": "16",
    }

    url = (
        "http://pda.leo.org/dictQuery/m-vocab/ende/query.xml" + "?" + urlencode(params)
    )

    user_agent = (
        "Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:15.0) Gecko/20100101 Firefox/15.0.1"
    )
    headers = {"User-Agent": user_agent}

    r = requests.get(url, headers=headers)
    content = r.text.encode(r.encoding)

    results = etree.fromstring(content)

    sections = results.find("sectionlist")
    for section in sections:
        print(header(section.get("sctTitle")))
        for entry in section.findall("entry"):
            wordl = process(getrepr(entry[0]))
            wordr = process(getrepr(entry[1]))

            esclen = 0
            for escseq in [bold, sgr0, sitm, ritm]:
                l = re.findall(re.escape(escseq), wordl)
                esclen += len(l) * len(escseq)

            print("{0: <{width}} {1}".format(wordl, wordr, width=colwidth + esclen))

    similar = results.find("similar")
    if len(similar):
        similardict = {}
        for side in similar:
            if side.find("word") is None:
                continue
            words = []
            for word in side:
                words.append(word.text)
            similardict[side.get("lang")] = words
        if similardict.keys():
            print(header("Orthographically similar words"))
            for key, val in similardict.items():
                print(subheader(key))
                print(" ".join(val))

    baseforms = results.find("baseform")
    if len(baseforms):
        basedict = {}
        for side in baseforms:
            if side.find("baselist") is None:
                continue
            words = []
            for base in side.find("baselist"):
                words.append(base.text)
            basedict[side.get("lang")] = words
        if basedict.keys():
            print(header("Potential base forms"))
            for key, val in basedict.items():
                print(subheader(key))
                print(" ".join(val))

    if not len(sections) and not len(similar) and not len(baseforms):
        print("No results found.")
        exit()


if __name__ == "__main__":
    main()
