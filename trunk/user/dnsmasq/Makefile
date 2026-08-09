SRC_NAME=dnsmasq-2.93
SRC_URL=https://thekelleys.org.uk/dnsmasq/$(SRC_NAME).tar.xz
THISDIR = $(shell pwd)

COPTS := -DHAVE_BROKEN_RTC -DNO_INOTIFY -DNO_AUTH -DNO_LOOP -DNO_DUMPFILE
ifdef CONFIG_IPV6
COPTS += -DCONFIG_IPV6
else
COPTS += -DNO_DHCP6
endif
ifndef CONFIG_USB_SUPPORT
COPTS += -DNO_TFTP
endif
ifneq ($(CONFIG_FIRMWARE_INCLUDE_IPSET),y)
COPTS += -DNO_IPSET
endif

CFLAGS += -ffunction-sections -fdata-sections
LDFLAGS += -Wl,--gc-sections

#all: download_test extract_test
all:
	$(MAKE) -j$(HOST_NCPU) -C $(SRC_NAME) CFLAGS="$(CFLAGS)" LDFLAGS="$(LDFLAGS)" COPTS="$(COPTS)"

download_test:
	( if [ ! -f $(SRC_NAME).tar.xz ]; then \
		wget -t5 --timeout=20 --no-check-certificate -O $(SRC_NAME).tar.xz $(SRC_URL); \
	fi )

extract_test:
	( if [ ! -d $(SRC_NAME) ]; then \
		tar xJf $(SRC_NAME).tar.xz; \
		find $(THISDIR)/patches -type f -name '*.patch' -print0 \
		  | sort -z \
		  | xargs -t -0 -n 1 patch -d $(SRC_NAME)  -p1 -i; \
	fi )

clean:
	$(MAKE) -C $(SRC_NAME) clean

romfs:
	$(ROMFSINST) $(SRC_NAME)/src/dnsmasq /usr/sbin/dnsmasq
