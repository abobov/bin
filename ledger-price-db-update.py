#!/usr/bin/env python
# -*- coding: utf-8 -*-
import os
from configparser import ConfigParser
import requests
import json
import datetime
from codecs import open

# Config sample:
#
# [fixer]
# access_key = 00000000000000000000000000000000
# base=RUB
#
# [exchange-symbols]
# USD=$
# EUR=€
# RUB=R
#
# [stocks]
# symbols=V,AMD
#
# [etf]
# symbols=FXUS

CONFIG_FILE = '~/.ledger-commodities'
current_date = datetime.datetime.now().strftime('%Y/%m/%d %H:%M:%S')
config = ConfigParser()
config.readfp(open(os.path.expanduser(CONFIG_FILE), 'r', 'utf-8'))


def get_json(url, **kwargs):
    response = requests.get(url, **kwargs)
    return json.loads(response.content)


def print_price(symbol, price, base):
    print ('P %s %s %f %s'  % (current_date, symbol, price, base)).encode('utf-8')


def exchange_rates():
    base = config.get('fixer', 'base')
    symbols = dict([(symbol.upper(), commodity) for symbol, commodity in config.items('exchange-symbols')])
    params = {
            "access_key": config.get('fixer', 'access_key'),
            "symbols": ','.join(symbols.keys() + [base,])
    }

    rates = get_json(r'http://data.fixer.io/api/latest', params=params)['rates']
    base_value = rates[base]
    for symbol, value in rates.items():
        if symbol != base:
            print_price(symbols[symbol], base_value / value, symbols[base])


def stocks():
    params = {
            "types": "ohlc",
            "symbols": config.get('stocks', 'symbols')
    }
    data = get_json(r'https://api.iextrading.com/1.0/stock/market/batch', params=params)
    for symbol in data.keys():
        price = data[symbol]['ohlc']['close']['price']
        print_price(symbol, price, '$')

def etfs():
    symbols = config.get('etf', 'symbols')
    for symbol in symbols.split(','):
        data = get_json(r'http://iss.moex.com/iss/engines/stock/markets/shares/boards/TQTF/securities/%s.jsonp' % symbol)

        value_index = data['marketdata']['columns'].index('LAST')
        value = data['marketdata']['data'][0][value_index]
        print_price(symbol, value, 'R')

def main():
    exchange_rates()
    stocks()
    etfs()

if __name__ == '__main__':
    main()
