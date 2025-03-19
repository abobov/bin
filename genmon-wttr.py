#!/usr/bin/env python3
# Based on thread https://forum.xfce.org/viewtopic.php?id=14357
import datetime
import logging
import sys
from argparse import ArgumentParser
from enum import Enum
from typing import NamedTuple
from urllib.parse import quote, urlencode, urlunparse
from zoneinfo import ZoneInfo

import requests

HPA_TO_MMHG_FACTOR = 760.0 / 101_325.0 * 100.0

# https://wttr.in/:help
# M - показывать скорость ветра в м/с
WTTR_DEFAULT_PARAMS = {
    "M": "",
    "T": "",
    "lang": "ru",
}


class WttrFormats(str, Enum):
    WEATHER_CONDITION = "%c"
    WEATHER_CONDITION_TEXTUAL_NAME = "%C"
    HUMIDITY = "%h"
    TEMPERATURE_ACTUAL = "%t"
    TEMPERATURE_FEELS_LIKE = "%f"
    WIND = "%w"
    LOCATION = "%l"
    MOON_PHASE = "%m"
    MOON_DAY = "%M"
    PRECIPITATION = "%p"
    PRESSURE = "%P"
    PRESSURE_MMHG = ""
    DAWN = "%D"
    SUNRISE = "%S"
    ZENITH = "%z"
    SUNSET = "%s"
    DUSK = "%d"
    CURRENT_TIME = "%T"
    TIMEZONE = "%Z"


class UrlComponents(NamedTuple):
    scheme: str
    netloc: str
    url: str
    path: str
    query: str
    fragment: str

    @staticmethod
    def create(**kwargs):
        return UrlComponents(
            scheme=kwargs.get("scheme", "https"),
            netloc=kwargs.get("netloc"),
            url=quote(kwargs.get("url")),
            path=kwargs.get("path"),
            query=urlencode(kwargs.get("query")),
            fragment=kwargs.get("fragment"),
        )


class WeatherData:
    def __init__(self, formats: list[WttrFormats], values: list[str]):
        self.__dict__["_data"] = dict(zip(formats, values))

    def __getattr__(self, name: str) -> str | None:
        return self._data.get(self._field_to_enum(name))

    def __setattr__(self, name: str, value: str) -> None:
        self._data[self._field_to_enum(name)] = value

    def _field_to_enum(self, name: str) -> WttrFormats:
        return WttrFormats[name.upper()]


def hpa_to_mmhg(pressure_hpa: int) -> int:
    return round(pressure_hpa * HPA_TO_MMHG_FACTOR)


def remove_redundant_temperature_sign(temperature: str) -> str:
    return temperature.lstrip("+").replace("-0", "0")


def remove_seconds_from_time(time: str) -> str:
    if time:
        return time[:-3]
    return time


def query_weather_data(location: str) -> WeatherData:
    formats = [
        WttrFormats.WEATHER_CONDITION,
        WttrFormats.HUMIDITY,
        WttrFormats.TEMPERATURE_ACTUAL,
        WttrFormats.TEMPERATURE_FEELS_LIKE,
        WttrFormats.WIND,
        WttrFormats.LOCATION,
        WttrFormats.MOON_PHASE,
        WttrFormats.MOON_DAY,
        WttrFormats.PRECIPITATION,
        WttrFormats.PRESSURE,
        WttrFormats.DAWN,
        WttrFormats.SUNRISE,
        WttrFormats.ZENITH,
        WttrFormats.SUNSET,
        WttrFormats.DUSK,
        WttrFormats.WEATHER_CONDITION_TEXTUAL_NAME,
        WttrFormats.TIMEZONE,
    ]
    params = dict(WTTR_DEFAULT_PARAMS)
    params["format"] = "\\n".join([format.value for format in formats])
    response = requests.get(f"https://wttr.in/{location}", params=params, timeout=10)
    if not response.ok:
        sys.exit(response.status_code)
    values = map(str.strip, response.text.splitlines())
    return WeatherData(formats, values)


def post_process_weather_data(weather_data: WeatherData):
    weather_data.pressure_mmhg = str(hpa_to_mmhg(int(weather_data.pressure.rstrip("hPa"))))
    weather_data.temperature_actual = remove_redundant_temperature_sign(weather_data.temperature_actual)
    weather_data.temperature_feels_like = remove_redundant_temperature_sign(weather_data.temperature_feels_like)
    for field in [WttrFormats.DAWN, WttrFormats.SUNRISE, WttrFormats.ZENITH, WttrFormats.SUNSET, WttrFormats.DUSK]:
        field_name = field.name
        setattr(weather_data, field_name, remove_seconds_from_time(getattr(weather_data, field_name)))


def print_genmon(weather: WeatherData) -> None:
    click_url = urlunparse(
        UrlComponents.create(
            netloc="wttr.in",
            url=weather.location,
            query=WTTR_DEFAULT_PARAMS,
        )
    )
    current_time = datetime.datetime.now(ZoneInfo(weather.timezone))

    print(f"""<txt><span size='x-large'>{weather.weather_condition}</span><span rise='0'> {weather.temperature_actual}</span></txt>
<txtclick>xfce4-terminal --hold --geometry=126x41 --title "Погода" --execute curl -s "{click_url}"</txtclick>
<tool><span font_desc='Bold 16'>{weather.weather_condition}</span> {weather.location}
{weather.temperature_actual} <small>и</small> {weather.weather_condition_textual_name}
<small>
Ощущается как:\t{weather.temperature_feels_like}
Влажность:\t{weather.humidity}
Ветер:\t\t{weather.wind}
Осадки:\t\t{weather.precipitation}
Давление:\t{weather.pressure_mmhg}

Восход/Закат:\t{weather.sunrise} / {weather.sunset}

Фаза луны:\t{weather.moon_phase}
</small>
<span size='x-small'>{current_time}</span></tool>""")


def main() -> None:
    parser = ArgumentParser()
    parser.add_argument("-l", "--location", default="")
    parser.add_argument("-v", "--verbose", action="store_true")
    args = parser.parse_args()

    if args.verbose:
        logging.basicConfig(level=logging.DEBUG)

    try:
        weather_data = query_weather_data(args.location)
        post_process_weather_data(weather_data)
        print_genmon(weather_data)
    except Exception as e:
        logging.critical(e, exc_info=args.verbose)
        sys.exit(1)


if __name__ == "__main__":
    main()
