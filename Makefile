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

PAYLOADS := $(wildcard *.S)
OBJECTS  := $(PAYLOADS:%.S=%.o)
BINS     := $(PAYLOADS:%.S=%.bin)
HEADERS  := $(PAYLOADS:%.S=%.h)

all: $(OBJECTS) $(BINS) $(HEADERS) gaster

gaster: gaster.c lzfse.c
	$(CC) $(CFLAGS) -Os $^ -o $@ $(EXTRAFLAGS) $(LDFLAGS)

%_armv7.o: %_armv7.S
	$(AS) -arch armv7 $< -o $@

%.o: %.S
	$(AS) -arch arm64 $< -o $@

%.bin: %.o
	$(OBJCOPY) -O binary -j .text $< $@

%.h: %.bin
	$(XXD) -iC $< $@

.PHONY: clean

clean:
	rm -rf gaster *.o *.h
