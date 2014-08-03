TECHSUPPORT_FRAMEWORK = $(THEOS_PROJECT_DIR)/../../_/Library/Frameworks

APPLICATION_NAME = TechSupport_Basic
PKG_ID = jp.ashikase.techsupport.demo.basic

TechSupport_Basic_FILES = main.m ApplicationDelegate.m RootViewController.m
TechSupport_Basic_CFLAGS = -F$(TECHSUPPORT_FRAMEWORK)
TechSupport_Basic_LDFLAGS = -F$(TECHSUPPORT_FRAMEWORK) -framework TechSupport
TechSupport_Basic_FRAMEWORKS = UIKit CoreGraphics

export ARCHS = armv6
export TARGET = iphone:clang
export TARGET_IPHONEOS_DEPLOYMENT_VERSION = 3.0

include theos/makefiles/common.mk
include $(THEOS_MAKE_PATH)/application.mk

after-install::
	- ssh idevice killall TechSupport_Basic

distclean: clean
	- rm -f $(THEOS_PROJECT_DIR)/$(PKG_ID)*.deb
	- rm -f $(THEOS_PROJECT_DIR)/.theos/packages/*
