#!/bin/sh
# Track both directions per client MAC, remap DHCP IP changes from the ARP
# table, and remove Internet access once the combined package quota is used.
CLIENTS=/etc/storage/ridoy_portal_clients.log
CLIENTS_TMP=/etc/storage/ridoy_portal_clients.log.tmp
STATE=/etc/storage/ridoy_portal_usage.state
COUNTERS=/tmp/ridoy_portal_counters.$$
NEXT=/etc/storage/ridoy_portal_usage.state.tmp
LOCK=/var/lock/ridoy_portal_quota.lock
[ -r "$CLIENTS" ] || exit 0
mkdir -p /etc/storage /var/lock
mkdir "$LOCK" 2>/dev/null || exit 0
trap 'rm -f "$COUNTERS" "$NEXT" "$CLIENTS_TMP"; rmdir "$LOCK" 2>/dev/null' EXIT HUP INT TERM
iptables-save -c -t filter 2>/dev/null | awk '
/-A RIDoyNetAcct -s / || /-A RIDoyNetAcct -d / {
  n=split($1,c,":"); if (n != 2) next;
  b=c[2]; gsub(/[^0-9]/,"",b);
  ip=$5; sub(/\/.*/,"",ip);
  if ($4=="-s") up[ip]+=b;
  else if ($4=="-d") down[ip]+=b;
}
END { for (ip in up) printf "%s %.0f %.0f\n",ip,down[ip]+0,up[ip]+0;
      for (ip in down) if (!(ip in up)) printf "%s %.0f %.0f\n",ip,down[ip]+0,up[ip]+0; }' > "$COUNTERS"
: > "$NEXT"
: > "$CLIENTS_TMP"
while IFS="$(printf '\t')" read -r name mac ip stamp quota extra; do
  case "$ip" in *[!0-9.]*|'') continue;; esac
  case "$quota" in ''|*[!0-9]*) continue;; esac
  old_ip=$ip
  if [ "$mac" != "-" ] && [ -r /proc/net/arp ]; then
    arp_ip=$(awk -v mac="$mac" 'tolower($4)==tolower(mac) && $3=="0x2" {print $1; exit}' /proc/net/arp)
    case "$arp_ip" in *[!0-9.]*|'') ;; *) ip=$arp_ip;; esac
  fi
  changed=0
  [ "$ip" = "$old_ip" ] || changed=1
  set -- $(awk -v ip="$ip" '$1==ip {print $2, $3}' "$COUNTERS")
  rx=\${1:-0}; tx=\${2:-0}
  old=$(awk -v mac="$mac" '$1==mac {print $3, $4, $5, $6}' "$STATE" 2>/dev/null)
  set -- $old
  prev_rx=\${1:-0}; prev_tx=\${2:-0}; sum_rx=\${3:-0}; sum_tx=\${4:-0}
  case "$prev_rx:$prev_tx:$sum_rx:$sum_tx:$rx:$tx" in *[!0-9:]* ) prev_rx=0; prev_tx=0; sum_rx=0; sum_tx=0;; esac
  dr=$(awk -v cur="$rx" -v prev="$prev_rx" 'BEGIN { d=cur-prev; if (d<0) d=cur; printf "%.0f", d }')
  dt=$(awk -v cur="$tx" -v prev="$prev_tx" 'BEGIN { d=cur-prev; if (d<0) d=cur; printf "%.0f", d }')
  sum_rx=$(awk -v a="$sum_rx" -v d="$dr" 'BEGIN { printf "%.0f", a+d }')
  sum_tx=$(awk -v a="$sum_tx" -v d="$dt" 'BEGIN { printf "%.0f", a+d }')
  total=$(awk -v a="$sum_rx" -v b="$sum_tx" 'BEGIN { printf "%.0f", a+b }')
  printf "%s %s %s %s %s %s\n" "$mac" "$ip" "$rx" "$tx" "$sum_rx" "$sum_tx" >> "$NEXT"
  printf "%s\t%s\t%s\t%s\t%s\n" "$name" "$mac" "$ip" "$stamp" "$quota" >> "$CLIENTS_TMP"
  exhausted=0
  if awk -v used="$total" -v quota="$quota" 'BEGIN { exit !(used >= quota) }'; then exhausted=1; fi
  if [ "$changed" = "1" ]; then
    /sbin/ipset del ridoy_portal_allow "$old_ip" >/dev/null 2>&1
    /sbin/iptables -D RIDoyNetAcct -s "$old_ip" -j RETURN >/dev/null 2>&1
    /sbin/iptables -D RIDoyNetAcct -d "$old_ip" -j RETURN >/dev/null 2>&1
    if [ "$exhausted" = "0" ]; then
      /sbin/ipset add ridoy_portal_allow "$ip" -exist >/dev/null 2>&1
      /sbin/iptables -D RIDoyNetAcct -s "$ip" -j RETURN >/dev/null 2>&1
      /sbin/iptables -A RIDoyNetAcct -s "$ip" -j RETURN >/dev/null 2>&1
      /sbin/iptables -D RIDoyNetAcct -d "$ip" -j RETURN >/dev/null 2>&1
      /sbin/iptables -A RIDoyNetAcct -d "$ip" -j RETURN >/dev/null 2>&1
    fi
  elif [ "$exhausted" = "1" ]; then
    /sbin/ipset del ridoy_portal_allow "$ip" >/dev/null 2>&1
  fi
  if [ "$exhausted" = "1" ]; then
    logger -t Ridoy.Net "prepaid quota exhausted for $mac ($total/$quota bytes)"
  fi
done < "$CLIENTS"
mv "$NEXT" "$STATE"
mv "$CLIENTS_TMP" "$CLIENTS"
exit 0
