TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ShanFontHook

ShanFontHook_FILES = Tweak.xm
ShanFontHook_CFLAGS = -fobjc-arc
ShanFontHook_FRAMEWORKS = UIKit CoreText

include $(THEOS)/makefiles/tweak.mk
