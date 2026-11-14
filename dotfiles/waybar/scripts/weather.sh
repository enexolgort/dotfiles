#!/usr/bin/env bash
# Waybar module: current weather and 3-day forecast from wttr.in.
# WEATHER_LOCATION empty = wttr.in guesses from the public IP.
set -uo pipefail

LOCATION="${WEATHER_LOCATION:-}"
LOCATION="${LOCATION// /+}"

if [ "${1:-}" = "--full" ]; then
  curl -fsS -m 10 "https://wttr.in/${LOCATION}?M" || echo "wttr.in unreachable"
  exit 0
fi

if ! data="$(curl -fsS -m 10 "https://wttr.in/${LOCATION}?format=j1" 2>/dev/null)"; then
  printf '{"text":"󰖐 ?","class":"unreachable","tooltip":"wttr.in unreachable"}\n'
  exit 0
fi

jq -c '
  def esc: gsub("&"; "&amp;") | gsub("<"; "&lt;") | gsub(">"; "&gt;");
  # WWO weather codes, see https://www.worldweatheronline.com/weather-api/api/docs/weather-icons.aspx
  def icon:
    tostring as $c
    | if $c == "113" then "󰖙"
      elif $c == "116" then "󰖕"
      elif ($c | IN("119", "122")) then "󰖐"
      elif ($c | IN("143", "248", "260")) then "󰖑"
      elif ($c | IN("200", "386", "389", "392", "395")) then "󰖓"
      elif ($c | IN("227", "230", "323", "326", "329", "332", "335", "338", "368", "371")) then "󰖘"
      elif ($c | IN("179", "182", "185", "281", "284", "311", "314", "317", "350", "362", "365", "374", "377")) then "󰙿"
      elif ($c | IN("299", "302", "305", "308", "356", "359")) then "󰖖"
      else "󰖗" end;
  .current_condition[0] as $now
  | (.nearest_area[0].areaName[0].value // "") as $area
  | {
      text: "\($now.weatherCode | icon) \($now.temp_C)°C",
      class: "ok",
      tooltip: (
        "<b>\($area | esc)</b>  \($now.weatherDesc[0].value | esc)\n"
        + "Feels like \($now.FeelsLikeC)°C · Humidity \($now.humidity)%\n"
        + "Wind \($now.windspeedKmph) km/h \($now.winddir16Point)\n"
        + "Sunrise \(.weather[0].astronomy[0].sunrise) · Sunset \(.weather[0].astronomy[0].sunset)\n\n"
        + (.weather | map(
            (.hourly | max_by(.chanceofrain | tonumber)) as $h
            | "<tt>\(.date[5:])</tt>  \(.hourly[4].weatherCode | icon)  \(.mintempC)° / \(.maxtempC)°  󰖗 \($h.chanceofrain)%"
          ) | join("\n"))
        + "\n\nClick: full forecast · Right-click: refresh"
      )
    }
' <<<"$data" 2>/dev/null || printf '{"text":"󰖐 ?","class":"unreachable","tooltip":"wttr.in sent an unexpected answer"}\n'
