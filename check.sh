#!/bin/bash
# Checks District for Avengers: Doomsday IMAX shows in Bengaluru; WhatsApps you via CallMeBot if found.
# Needs secrets: WHATSAPP_PHONE (e.g. +91XXXXXXXXXX) and CALLMEBOT_APIKEY.
URL="https://www.district.in/movies/avengers-doomsday-movie-tickets-in-bengaluru-MV176735"
UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0 Safari/537.36"

send_whatsapp() {
  curl -s -G "https://api.callmebot.com/whatsapp.php" \
    --data-urlencode "phone=$WHATSAPP_PHONE" \
    --data-urlencode "text=$1" \
    --data-urlencode "apikey=$CALLMEBOT_APIKEY" > /dev/null
}

if [[ "$TEST_MODE" == "true" ]]; then
  send_whatsapp "✅ Test: your IMAX watcher is set up and running in the cloud."
  echo "Test message sent."
fi

code=$(curl -s -L -A "$UA" -o page.html -w "%{http_code}" --max-time 30 "$URL")
if [[ "$code" != "200" ]]; then echo "Fetch failed: HTTP $code"; exit 1; fi
if ! grep -q 'Avengers: Doomsday' page.html; then echo "Movie not found on page (layout changed?)"; exit 1; fi

named=$(grep -oiE '"name":"Avengers: Doomsday[^"]*IMAX[^"]*"' page.html | sort -u)
count=$(grep -oi 'imax' page.html | wc -l | tr -d ' ')
echo "imax mentions=$count named=$named"

if [[ -n "$named" || "$count" -gt 2 ]]; then
  send_whatsapp "🎬 *IMAX TICKETS ARE LIVE!* Avengers: Doomsday IMAX shows just appeared in Bengaluru on District. Book NOW (check BookMyShow too): $URL"
  echo "FOUND=true" >> "$GITHUB_OUTPUT"
else
  echo "No IMAX yet."
fi
