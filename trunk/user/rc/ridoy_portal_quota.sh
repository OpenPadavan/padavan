#!/bin/sh
# Enforce prepaid Ridoy.Net data quotas using the router's per-client
# FORWARD byte counters. The watchdog invokes this every 10 seconds.
CLIENTS=/etc/storage/ridoy_portal_clients.log
STATE=/etc/storage/ridoy_portal_usage.state
COUNTERS=/tmp/ridoy_portal_counters.$$
NEXT=/etc/storage/ridoy_portal_usage.state.tmp
LOCK=/var/lock/ridoy_portal_quota.lock

[ -r "$CLIENTS" ] || exit 0
mkdir -p /etc/storage /var/lock
mkdir "$LOCK" 2>/dev/null || exit 0
trap 'rm -f "$COUNTERS" "$NEXT"; rmdir "$LOCK" 2>/dev/null' EXIT HUP INT TERM

# Parse the two independent counters installed in RIDoyNetAcct:
# -s client = upload, -d client = download. Sum both exactly once.
iptables-save -c -t filter 2>/dev/null | awk '
/-A RIDoyNetAcct -s / || /-A RIDoyNetAcct -d / {
  n=split($1,c,":"); if (n != 2) next;
  b=c[2]; gsub(/[^0-9]/,"",b);
  ip=$5; sub(/\/.*/,"",ip);
  if ($4=="-s") up[ip]+=b;
  else if ($4=="-d") down[ip]+=b;
}
END { for (ip in up) printf "%s %u %u\n",ip,down[ip]+0,up[ip]+0;
      for (ip in down) if (!(ip in up)) printf "%s %u %u\n",ip,down[ip]+0,up[ip]+0; }' > "$COUNTERS"

: > "$NEXT"
while IFS="$(printf '\t')" read -r name mac ip stamp quota extra; do
  case "$ip" in *[!0-9.]*|'') continue;; esac
  case "$quota" in ''|*[!0-9]*) continue;; esac
  set -- $(awk -v ip="$ip" '$1==ip {print $2, $3}' "$COUNTERS")
  rx=${1:-0}; tx=${2:-0}
  old=$(awk -v ip="$ip" '$1==ip {print $2, $3, $4, $5}' "$STATE" 2>/dev/null)
  set -- $old
  prev_rx=${1:-0}; prev_tx=${2:-0}; sum_rx=${3:-0}; sum_tx=${4:-0}
  case "$prev_rx:$prev_tx:$sum_rx:$sum_tx:$rx:$tx" in *[!0-9:]* ) prev_rx=0; prev_tx=0; sum_rx=0; sum_tx=0;; esac
  if [ "$rx" -ge "$prev_rx" ] 2>/dev/null; then dr=$((rx-prev_rx)); else dr=$rx; fi
  if [ "$tx" -ge "$prev_tx" ] 2>/dev/null; then dt=$((tx-prev_tx)); else dt=$tx; fi
  sum_rx=$((sum_rx+dr)); sum_tx=$((sum_tx+dt))
  total=$((sum_rx+sum_tx))
  printf "%s %s %s %s %s\n" "$ip" "$rx" "$tx" "$sum_rx" "$sum_tx" >> "$NEXT"
  if [ "$total" -ge "$quota" ] 2>/dev/null; then
    /sbin/ipset del ridoy_portal_allow "$ip" >/dev/null 2>&1
    logger -t Ridoy.Net "prepaid quota exhausted for $ip ($total/$quota bytes)"
  fi
done < "$CLIENTS"

mv "$NEXT" "$STATE"
exit 0
