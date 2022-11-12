AS      ?= as
CC      ?= cc
XXD     ?= xxd
OBJCOPY ?= gobjcopy
SDKROOT ?= $(shell xcrun -sdk macosx -show-sdk-path)

ifeq ($(LIBUSB),1)
CFLAGS  ?= -Wall -Wextra -Wpedantic -DHAVE_LIBUSB
LDFLAGS ?= -lusb-1.0 -lcrypto
else
CFLAGS  ?= -Weverything -framework CoreFoundation -framework IOKit
endif

ifeq ($(shell sw_vers -productName),macOS)
EXTRAFLAGS := -mmacosx-version-min=10.9
endif

ifeq ($(shell sw_vers -productName),iPhone OS)
EXTRAFLAGS := -arch armv7 -arch arm64 -mios-version-min=9.0 -isystem $(SDKROOT)
endif

all: payload gaster

gaster: gaster.c lzfse.c
	$(CC) $(CFLAGS) -Os $(LDFLAGS) $^ -o $@ $(EXTRAFLAGS)

payload_$(PAYLOAD).o: payload_$(PAYLOAD).S
	$(AS) -arch arm64 $< -o $@

payload_$(PAYLOAD).bin: payload_$(PAYLOAD).o
	$(OBJCOPY) -O binary -j .text $< $@

payload_$(PAYLOAD).h: payload_$(PAYLOAD).bin
	$(XXD) -iC $< $@

.PHONY: clean

clean:
	rm -rf gaster *.o

payload: payload_$(PAYLOAD).h
