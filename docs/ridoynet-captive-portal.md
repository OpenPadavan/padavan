# Ridoy.Net captive portal

The TP-Link TL-WR845N V4 Padavan template includes an optional Ridoy.Net captive-portal integration.

## Intended flow

1. A new IPv4 Wi-Fi client receives DHCP and router DNS service.
2. Unapproved client DNS requests are sent to the router.
3. Unapproved plain-HTTP requests are redirected to the router's built-in web server and display `captive_portal.html`.
4. Pressing **Continue to Internet** adds the source IPv4 address observed by the HTTP server to the `ridoy_portal_allow` IPSet for 86,400 seconds.
5. The IPv4 firewall permits that client to route traffic until the IPSet entry expires.

The portal does not intercept HTTPS. Android, iOS, Windows and other captive-network detection behaviour differs; some devices may require opening an ordinary HTTP page (for example `http://neverssl.com`) to display the sign-in page.

## IPv6 limitation

This first implementation is IPv4-only. While the portal is active, routed IPv6 traffic from LAN clients is blocked to prevent bypassing the IPv4 access gate. IPv6 Internet access is therefore unavailable during portal mode.

## Disable the portal

From an authenticated router shell:

```sh
nvram set ridoy_portal_enable=0
nvram commit
reboot
```

Re-enable with `nvram set ridoy_portal_enable=1`, then run `nvram commit` and `reboot`.

## Safety / build status

This source change is not proof that the firmware is compatible with a particular physical router. Build output must pass the repository's CI checks and be tested on the exact hardware before anyone considers installation. Do not flash an image solely because the compilation job succeeds.
