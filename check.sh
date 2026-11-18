#!/bin/bash
# Checks District for Avengers: Doomsday IMAX shows in Bengaluru; sends a phone alert via ntfy if found.
# Needs one secret: NTFY_TOPIC (your private ntfy topic name).
URL="https://www.district.in/movies/avengers-doomsday-movie-tickets-in-bengaluru-MV176735"
UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0 Safari/537.36"

notify() {  # $1 = title, $2 = message, $3 = priority (default/high/urgent)
  curl -s -H "Title: $1" -H "Priority: $3" -H "Tags: movie_camera" -H "Click: $URL" \
    -d "$2" "https://ntfy.sh/$NTFY_TOPIC" > /dev/null
}

if [[ "$TEST_MODE" == "true" ]]; then
  notify "IMAX watcher is running" "Test: your cloud watcher is set up. You'll get an URGENT alert when IMAX shows open in Bengaluru." default
  echo "Test notification sent."
fi

# District sometimes refuses some cloud computers, so retry up to 4 times before giving up.
ok=false
for attempt in 1 2 3 4; do
  code=$(curl -s -L -A "$UA" -H "Accept-Language: en-IN,en;q=0.9" -o page.html -w "%{http_code}" --max-time 30 "$URL")
  if [[ "$code" == "200" ]] && grep -q 'Avengers: Doomsday' page.html; then ok=true; break; fi
  echo "Attempt $attempt failed (HTTP $code)"; sleep 15
done
if [[ "$ok" != "true" ]]; then
  # Not a real error, just a skipped check. Exit 0 so GitHub doesn't email you every 5 minutes.
  echo "::warning::Could not read District this time (last HTTP $code). Will try again on the next run."
  exit 0
fi

named=$(grep -oiE '"name":"Avengers: Doomsday[^"]*IMAX[^"]*"' page.html | sort -u)
count=$(grep -oi 'imax' page.html | wc -l | tr -d ' ')
echo "imax mentions=$count named=$named"

if [[ -n "$named" || "$count" -gt 2 ]]; then
  for i in 1 2 3; do
    notify "IMAX TICKETS ARE LIVE!" "Avengers: Doomsday IMAX shows just appeared in Bengaluru on District. Tap to book NOW (check BookMyShow too)." urgent
    sleep 20
  done
  echo "FOUND=true" >> "$GITHUB_OUTPUT"
else
  echo "No IMAX yet."
fi
