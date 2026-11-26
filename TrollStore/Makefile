TARGET := appletv:clang:16.4:14.0
INSTALL_TARGET_PROCESSES = TrollStore
ARCHS = arm64

TARGET_CODESIGN = ../Exploits/fastPathSign/fastPathSign

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = TrollStore

TrollStore_FILES = $(wildcard *.m) $(wildcard ../Shared/*.m)

ifeq ($(THEOS_TARGET_NAME),appletv)
# tvOS 没有 Preferences/PSListController 私有框架；用原生 UITableViewController 设置页替代
TrollStore_FILES := $(filter-out TSSettingsListController.m TSSettingsAdvancedListController.m TSDonateListController.m ../Shared/TSListControllerShared.m,$(TrollStore_FILES))
TrollStore_FILES += TSTVSettingsController.m
endif
TrollStore_FRAMEWORKS = UIKit CoreGraphics CoreServices
TrollStore_PRIVATE_FRAMEWORKS =
TrollStore_LIBRARIES = archive
TrollStore_CFLAGS = -fobjc-arc -I../Shared -I$(shell brew --prefix)/opt/libarchive/include
TrollStore_CODESIGN_FLAGS = --entitlements entitlements.plist

include $(THEOS_MAKE_PATH)/application.mk
