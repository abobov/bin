#!/usr/bin/env python
# -*- coding: utf-8 -*-
from os import path
from xml.etree import ElementTree as etree
import argparse

def update_text(tree, name, value=None, func=None):
    e = tree.find(name)
    if value is not None:
        e.text = value
    elif func is not None:
        e.text = func(e.text)

def update(fname, args):
    tree = etree.parse(fname)
    update_text(tree, 'InputFilename', func=path.basename)
    update_text(tree, 'OutputFilename', func=path.basename)
    if args.saturation is not None:
        update_text(tree, 'Saturation', value=args.saturation)
    tree.write(fname, encoding='utf-8', xml_declaration=True)

def setup_parser():
    parser = argparse.ArgumentParser(description='Remove path from input and output file names.')
    parser.add_argument('--saturation', metavar='SAT',
            help='Adjust the color saturation. Range 0.00 to 8.00. Default 1.0, use 0 for black & white output.')
    parser.add_argument('files', metavar='FILES', nargs=argparse.REMAINDER,
            help='Input UFRaw ID-files.')
    return parser

def main():
    parser = setup_parser()
    args = parser.parse_args()
    if len(args.files) == 0:
        parser.print_help()
    for f in filter(path.isfile, args.files):
        update(f, args)

if __name__ == '__main__':
    main()

