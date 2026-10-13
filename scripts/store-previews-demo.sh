#!/usr/bin/env bash
# Runs in the guest, for scripts/store-previews.sh: demo data for the store widgets that
# otherwise only say how to set them up. `gh` answers like a signed-in account, Home
# Assistant's states are files that curl reads, `curl` answers Cursor's dashboard, and
# the Tesla tile reads its own fixture. With "off", puts everything back.
set -u
demo=/tmp/store-previews-demo
ha=~/.config/omarchy-proot/home-assistant
cursor=~/.config/cursor/auth.json
tesla=~/.config/omarchy-tesla/fixture.json

# Moves a real file aside before the demo writes its own; "off" puts it back.
aside() { [ -f "$1" ] && [ ! -f "$1.before-demo" ] && mv "$1" "$1.before-demo"; mkdir -p "${1%/*}"; }

if [ "${1:-}" = off ]; then
  rm -rf "$demo" /usr/local/bin/gh /usr/local/bin/curl
  for f in "$ha" "$cursor" "$tesla"; do
    [ -f "$f.before-demo" ] && mv "$f.before-demo" "$f" || rm -f "$f"
  done
  exit 0
fi

mkdir -p "$demo/api/states" /usr/local/bin
cat > /usr/local/bin/gh <<'EOF'
#!/bin/sh
case "$*" in
  auth*) exit 0 ;;
  api*) echo 4 ;;
  *review-requested*) echo 2 ;;
  search*) cat <<'JSON'
[{"title":"Add previews for every widget","url":"https://github.com/","repository":{"name":"omarchy-widgets"},"updatedAt":"2026-10-07T09:00:00Z"},
 {"title":"Store: categories, search and a detail page","url":"https://github.com/","repository":{"name":"omarchy-widgets"},"updatedAt":"2026-10-06T09:00:00Z"},
 {"title":"Fix wrapping of long command lines","url":"https://github.com/","repository":{"name":"omarchy-proot"},"updatedAt":"2026-10-05T09:00:00Z"},
 {"title":"Bump the checker to owl 2","url":"https://github.com/","repository":{"name":"omarchy-widgets"},"updatedAt":"2026-10-04T09:00:00Z"}]
JSON
    ;;
esac
EOF
chmod +x /usr/local/bin/gh

state() { printf '{"entity_id":"%s","state":"%s","attributes":{"friendly_name":"%s","unit_of_measurement":"%s"}}' "$1" "$2" "$3" "${4:-}" > "$demo/api/states/$1"; }
state light.living_room on "Living room"
state light.kitchen off "Kitchen"
state sensor.indoor 21.5 "Indoor" "°C"
state sensor.power 342 "Power use" "W"
state lock.front_door locked "Front door"
state switch.coffee_machine on "Coffee machine"
aside "$ha"
printf 'file://%s\ndemo\nlight.living_room\nlight.kitchen\nsensor.indoor\nsensor.power\nlock.front_door\nswitch.coffee_machine\n' "$demo" > "$ha"

# Cursor's Pro+ plan, from the cursor-plan author's own picture. Everything else goes to curl.
aside "$cursor"
echo '{"accessToken":"demo"}' > "$cursor"
cat > /usr/local/bin/curl <<'EOF'
#!/bin/sh
case "$*" in
  *DashboardService/GetCurrentPeriodUsage*) echo '{"billingCycleEnd":"1792627200000","planUsage":{"totalPercentUsed":77,"apiPercentUsed":96,"includedSpend":7000,"limit":7000}}' ;;
  *DashboardService/GetPlanInfo*) echo '{"planInfo":{"planName":"Pro+","price":"$60/mo"}}' ;;
  *) exec /usr/bin/curl "$@" ;;
esac
EOF
chmod +x /usr/local/bin/curl

# The made-up car from the tesla README: Bluebird, parked at 54% with an 80% charge limit.
aside "$tesla"
cat > "$tesla" <<'JSON'
{"name":"Bluebird","vin":"5YJ3E1EA0PF000001","car_type":"model 3","state":"online","shift":"P","driving":false,
 "speed_unit":"mph","battery":54,"charge_limit":80,"charging":"Disconnected","range":168,"range_unit":"mi",
 "odometer":12840,"locked":true,"sentry":false,"climate_on":false,"inside_temp":72,"outside_temp":64,"temp_unit":"°F",
 "tyres":{"min":41,"max":42},"tyre_fl":42,"tyre_fr":42,"tyre_rl":41,"tyre_rr":41,"tyre_unit":"psi",
 "software":"2026.32.6","open":[],"vehicles":[{"vin":"5YJ3E1EA0PF000001","name":"Bluebird"}]}
JSON
