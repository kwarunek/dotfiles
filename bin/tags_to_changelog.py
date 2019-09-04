#!/usr/bin/env python

import sys
import os
from subprocess import Popen, PIPE


tags = {}
raw = Popen(['git', 'for-each-ref', '--format="%(refname:short) %(taggerdate:short) %(subject)"', 'refs/tags'], stdout=PIPE)
lines = raw.stdout.read().decode('utf-8').replace('"', '').split('\n')

for line in lines:
    if not line: continue
    tag, rest = line.strip().split(' ', 1)
    rest = rest.strip()
    try:
        date, msg = rest.split(' ', 1)
        date = date.strip()
        if len(date) != 10:
            raise ValueError('No date in log')
    except Exception:
        date = None
        msg = rest
    tags[tag] = (date, msg)

print('''# Changelog

All changes must be documented in this file along with PR.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

Versioning  X.Y.Z:
 X - breaking changes
 Y - non breaking features, notable bugfixes
 Z - bugfixes, small improvments


''')

for tag in reversed(sorted(tags)):
    date = u'- {}'.format(tags[tag][0]) if tags[tag][0] is not None else ''
    print(u'## [{}] {}'.format(tag, date))
    print('### Changed')
    print(u'- {}'.format(tags[tag][1]))
    print('\n')
