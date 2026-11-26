TARGET := appletv:clang:16.4:14.0
ARCHS = arm64

ifdef TROLLSTORE_LITE
HELPER_NAME = trollstorehelper_lite
else
HELPER_NAME = trollstorehelper
TARGET_CODESIGN = ../Exploits/fastPathSign/fastPathSign
endif

include $(THEOS)/makefiles/common.mk

TOOL_NAME = $(HELPER_NAME)

$(HELPER_NAME)_FILES = $(wildcard *.m) $(wildcard ../Shared/*.m) $(wildcard ../ChOma/src/*.c)

ifndef TROLLSTORE_LITE
$(HELPER_NAME)_FILES += ../Exploits/fastPathSign/src/coretrust_bug.c ../Exploits/fastPathSign/src/codesign.m
$(HELPER_NAME)_CODESIGN_FLAGS = --entitlements entitlements.plist
ifeq ($(THEOS_TARGET_NAME),appletv)
$(HELPER_NAME)_LDFLAGS = -L../ChOma/external/tvos -lcrypto
else
$(HELPER_NAME)_LDFLAGS = -L../ChOma/external/ios -lcrypto
endif
else
$(HELPER_NAME)_CODESIGN_FLAGS = -Sentitlements.plist
endif
 
ifeq ($(THEOS_TARGET_NAME),appletv)
# tvOS 无 Preferences 私有框架；helper 为 CLI，不需要设置页 UI
$(HELPER_NAME)_FILES := $(filter-out ../Shared/TSListControllerShared.m,$($(HELPER_NAME)_FILES))
endif

$(HELPER_NAME)_CFLAGS = -fobjc-arc -I../Shared -I../ChOma/external/tvos-include -I../ChOma/src -I../Exploits/fastPathSign/src -I$(shell brew --prefix)/opt/libarchive/include

$(HELPER_NAME)_INSTALL_PATH = /usr/local/bin
$(HELPER_NAME)_LIBRARIES = archive
# tvOS SDK 无私有框架桩；私有类/符号一律运行时 dlopen + NSClassFromString/dlsym

ifdef TROLLSTORE_LITE
$(HELPER_NAME)_CFLAGS += -DTROLLSTORE_LITE -DDISABLE_SIGNING=1
endif

include $(THEOS_MAKE_PATH)/tool.mk
