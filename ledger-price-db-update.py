#!/usr/bin/env python
# -*- coding: utf-8 -*-
import os
import sys
import traceback
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
#
# [bond]
# RUS-20=XS0088543193

CONFIG_FILE = '~/.ledger-commodities'
config = ConfigParser()
config.readfp(open(os.path.expanduser(CONFIG_FILE), 'r', 'utf-8'))


def get_json(url, **kwargs):
    response = requests.get(url, **kwargs)
    return json.loads(response.content)


def print_price(symbol, price, base, date=datetime.datetime.now()):
    date_str = date.strftime('%Y/%m/%d %H:%M:%S')
    if ' ' in symbol:
        symbol = '"' + symbol +'"'
    print ('P %s %s %f %s'  % (date_str, symbol, price, base)).encode('utf-8')


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
    for symbol in config.get('stocks', 'symbols').split(','):
        params = { "assetclass": "stocks" }
        url = r'https://api.nasdaq.com/api/quote/%s/info' % (symbol)
        response = requests.get(url, params=params)
        data = json.loads(response.content)
        price = float(data['data']['keyStats']['PreviousClose']['value'][1:])
        print_price(symbol, price, '$')

def get_moex_value(data, name):
    if 'columns' in data:
        index = data['columns'].index(name)
        if 'data' in data:
            if len(data['data']) > 0:
                return data['data'][0][index]
    return None

def etfs():
    symbols = config.get('etf', 'symbols')
    for symbol in symbols.split(','):
        data = get_json(r'http://iss.moex.com/iss/engines/stock/markets/shares/boards/TQTF/securities/%s.jsonp' % symbol)['marketdata']

        value = get_moex_value(data, 'LAST')
        print_price(symbol, value, 'R')

def bonds():
    symbols = config.items('bond')
    date = datetime.datetime.now() - datetime.timedelta(days=1)
    date_str = date.strftime('%Y-%m-%d')
    for short, symbol in symbols:
        if symbol.startswith('SU') or symbol.startswith('RU'):
            if symbol.startswith('SU'):
                url = r'https://iss.moex.com/iss/engines/stock/markets/bonds/boards/TQOB/securities/%s.jsonp?from=%s' % (symbol, date_str)
            else:
                url = r'https://iss.moex.com/iss/engines/stock/markets/bonds/boards/EQOB/securities/%s.jsonp?from=%s' % (symbol, date_str)
            data = get_json(url)['securities']
            price = get_moex_value(data, 'PREVPRICE')
            value = get_moex_value(data, 'FACEVALUE')
            accrued = get_moex_value(data, 'ACCRUEDINT')
            if price is None or value is None or accrued is None:
                continue
            print_price(short.upper(), price / 100.0 * value + accrued, 'R', date)
        else:
            url = r'https://iss.moex.com/iss/history/engines/stock/markets/bonds/boards/TQOD/securities/%s.jsonp?from=%s' % (symbol, date_str)
            data = get_json(url)['history']
            if len(data['data']) > 0:
                value = get_moex_value(data, 'CLOSE')
                nominal = get_moex_value(data, 'FACEVALUE')
                currency = get_moex_value(data, 'FACEUNIT')
                if currency == 'USD':
                    currency = '$'
                elif currency == 'EUR':
                    currency = '€'
                elif currency == 'RUB':
                    currency = 'R'
                if value is None or nominal is None or currency is None:
                    continue
                print_price(short.upper(), value * nominal / 100.0, currency, date)


def main():
    updates = [exchange_rates, stocks, etfs, bonds]
    for update in updates:
        try:
            update()
        except Exception as e:
            print >> sys.stderr, 'Oops, update method `%s` failed: %s' % (update, e)
            traceback.print_exc()

if __name__ == '__main__':
    main()
