# padavan

[![License: GPL-2.0](https://img.shields.io/badge/License-GPL--2.0-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
[![build](https://github.com/OpenPadavan/padavan/actions/workflows/build.yml/badge.svg)](https://github.com/OpenPadavan/padavan/actions/workflows/build.yml)

Custom firmware for Ralink/MediaTek-based routers. Built on top of the original **Padavan** firmware by **Andy Padavan**, this project aims to improve the supported devices on the software side, giving power users full control over their hardware.

> **Warning:** This project comes without warranty or support. Installing it will probably void your warranty.
> Contributors are not responsible for what happens next. **Flash at your own risk!**

## Maintainer

- **Andy Padavan** — original firmware author
- **OpenPadavan** — current maintainer — https://github.com/OpenPadavan/padavan

## Features

- Linux kernel **3.4.x** for Ralink **RT3883 / MT7620 / MT7621 / MT7628** SoCs
- Full-featured web UI (AsusWRT-style interface, multi-language)
- USB support: storage (NTFS/exFAT/EXT/XFS/HFS+), print server, modem/3G, audio, UVC
- VPN: OpenVPN, WireGuard, AmneziaWG, PPTP/L2TP clients, DNS-over-HTTPS
- Advanced networking: QoS, iptables/ipset, IPv6, multicast (udpxy/xupnpd)
- P2P & media: Transmission, aria2, Samba, miniDLNA, minisatip, vsftpd
- Entware/optware integration

## Repository layout

```
├── toolchain/    # crosstool-NG based toolchain builder
├── trunk/        # firmware source tree
│   ├── linux-3.4.x/  # kernel
│   ├── configs/      # board definitions & .config templates
│   ├── user/         # userland packages (~80)
│   ├── proprietary/  # vendor WiFi / hardware NAT drivers
│   └── build_firmware.sh
└── uboot/        # bootloader sources
```

## Prerequisites

Build only on **Ubuntu Desktop 22.04.4 LTS (Jammy Jellyfish)**, x86_64. Before building, run "App Updates" and then update the system:

```shell
sudo apt update
sudo apt upgrade
sudo apt install autoconf autoconf-archive automake autopoint bison build-essential ca-certificates cmake cpio curl dos2unix doxygen fakeroot flex gawk gettext git gperf help2man htop kmod libarchive-tools libblkid-dev libc-ares-dev libcurl4-openssl-dev libdevmapper-dev libev-dev libevent-dev libexif-dev libflac-dev libgmp3-dev libid3tag0-dev libidn2-dev libjpeg-dev libkeyutils-dev libltdl-dev libmpc-dev libmpfr-dev libncurses5-dev libogg-dev libsqlite3-dev libssl-dev libsystemd-dev libtool libtool-bin libudev-dev libunbound-dev libvorbis-dev libxml2-dev locales mc nano pkg-config ppp-dev python3 python3-docutils sshpass texinfo unzip uuid uuid-dev vim wget xxd zlib1g-dev
```

A ready-to-use build container is also provided — see `Dockerfile` / `docker-compose.yml`.

## Building

### 1. Build the toolchain

```shell
cd toolchain
./build_toolchain.sh        # installs to toolchain/out
cd ..
```

### 2. Select a board configuration

Pick a `.config` template from `trunk/configs/templates/<vendor>/` and copy it into the tree:

```shell
cd trunk
cp configs/templates/asus/rt-n56u.config .config
```

Supported vendors: `asus`, `xiaomi`, `hiwifi`, `newifi`, `phicomm`, `tplink`, `gl`, `dlink`, `linksys`, `totolink`, `zte`, `zyxel`, and more — see `trunk/configs/templates/`.

### 3. Build the firmware

```shell
./build_firmware.sh
```

The build copies the board kernel/BusyBox configs, assembles the proprietary drivers, and runs `make`. Output images land in `trunk/images/`.

### 4. Clean build artifacts

```shell
./clear_tree.sh
```

> Note: after updating the toolchain/uClibc, run `build_toolchain.sh` again before rebuilding.

## Firmware management

| Setting | Value |
|---|---|
| Web UI | `192.168.1.1` or `http://my.router` |
| User | `admin` |
| Password | `admin` |
| WiFi 2.4 GHz | `Padavan_2.4GHz` |
| WiFi 5 GHz | `Padavan_5GHz` |
| WiFi password | `1234567890` |

### Automated builds (GitHub Actions)

This repository ships its own CI workflow (`.github/workflows/build.yml`) that builds firmware on GitHub's servers.

The workflow runs in two modes:

| Event | Action |
|---|---|
| `push` / `pull_request` | **Validation only** — checks every board template maps to a real board directory. No firmware is built. |
| `workflow_dispatch` (manual) | **Build** — requires you to explicitly pick the router(s) to build. |

**To build firmware manually:**

1. Open the **Actions** tab and select the **build** workflow.
2. Click **Run workflow**.
3. Fill in the **Router(s) to build** field (`boards`, required):
   - a single board: `xiaomi/mi-3`
   - several boards, comma-separated: `xiaomi/mi-3,phicomm/psg1218,tplink/tl_wr841n-v13`
   - all boards: `all`
4. Optionally add **config overrides** (`config`) to customize the firmware — see below.
5. Click the green **Run workflow** button.

Every board name is validated before the build starts; unknown boards abort the run with a clear error.
Finished runs publish the firmware as downloadable artifacts (retained for a limited time, for personal use — the firmware license does not permit binary redistribution).

**Customizing the firmware build** (`config` input):

The `config` field accepts extra `CONFIG_*` lines that are appended to the selected board template before compiling — e.g. to add packages or change kernel options:

```text
CONFIG_FIRMWARE_INCLUDE_ARIA=y
CONFIG_FIRMWARE_INCLUDE_TOR=y
```

Only `CONFIG_*=...` assignments, `#` comments and blank lines are allowed; anything else fails the run. The full list of options is documented in `trunk/configs/templates/<vendor>/<board>.config`.

To change the defaults permanently, edit the board template under `trunk/configs/templates/<vendor>/` — each template's `CONFIG_VENDOR` / `CONFIG_FIRMWARE_PRODUCT_ID` must keep matching a directory under `trunk/configs/boards/<vendor>/<product-id>/` (this is validated in CI).

> Reference workflow maintained by the community: [padavan-builder-workflow](https://github.com/shvchk/padavan-builder-workflow) — automated Padavan firmware builds on GitHub servers

## Contributing

Feel free to open issues and send pull requests with improvements or fixes. Note that whether a proposed change gets merged depends on verification/testing of the particular change and on maintainer availability.

## License

This project is released under the **GNU General Public License version 2 (GPL-2.0)** — see `trunk/License`.
Third-party sources bundled in this tree remain under their respective licenses.

## Disclaimer

**No warranty or support.** This product includes copyrighted third-party software licensed under the terms of the GNU General Public License. See the GPL for the exact terms and conditions.

The firmware or any other product designed or produced by this project may contain, in whole or in part, pre-release, untested, or not fully tested works, and may contain errors that could cause failures or loss of data. Use of this software is at your sole and entire risk.

ANY PRODUCT IS PROVIDED "AS IS" AND WITHOUT WARRANTY, UPGRADES OR SUPPORT OF ANY KIND. ALL CONTRIBUTORS EXPRESSLY DISCLAIM ALL WARRANTIES AND/OR CONDITIONS, EXPRESS OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES AND/OR CONDITIONS OF SATISFACTORY QUALITY, OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY, OF QUIET ENJOYMENT, AND NON-INFRINGEMENT OF THIRD PARTY RIGHTS.
