#!/usr/bin/env python

import glob

tags = []

def write_tag(tag):
    with open('./tags/%s.md' % tag, 'w') as f:
        f.write('---\n')
        f.write('layout: tagpage\n')
        f.write('title: "Tag: %s"\n' % tag)
        f.write('tag: %s\n' % tag)
        f.write('---\n')


for fname in glob.glob('./_posts/*.md'): 
    with open(fname, 'r') as f:
        l = f.readline()

        # Check if front matter exists
        if l.strip() == '---': 
            done = False
            l = f.readline().strip()
        else: 
            done = True

        # Ensure we have not reached EOF
        # Note: empty lines will have l == '\n'
        # https://docs.python.org/3.6/tutorial/inputoutput.html#methods-of-file-objects
        while not done:
            if l.startswith('tags'):
                done = True
                tag_string = l.split(':')[1].strip()
                tags += tag_string.split()
            l = f.readline()
            if l == '': done = True
            l = l.strip()
            if l == '---': done = True
            
for tag in tags:
    write_tag(tag)