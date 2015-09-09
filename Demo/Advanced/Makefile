TECHSUPPORT_FRAMEWORK = $(THEOS_PROJECT_DIR)/../../_/Library/Frameworks

APPLICATION_NAME = TechSupport_Advanced
PKG_ID = jp.ashikase.techsupport.demo.advanced

TechSupport_Advanced_FILES = main.m ApplicationDelegate.m RootViewController.m
TechSupport_Advanced_CFLAGS = -F$(TECHSUPPORT_FRAMEWORK) -I../../Libraries/Common
TechSupport_Advanced_LDFLAGS = -F$(TECHSUPPORT_FRAMEWORK) -framework TechSupport -llockdown
TechSupport_Advanced_FRAMEWORKS = UIKit CoreGraphics

export ARCHS = armv6
export TARGET = iphone:clang
export TARGET_IPHONEOS_DEPLOYMENT_VERSION = 3.0

include theos/makefiles/common.mk
include $(THEOS_MAKE_PATH)/application.mk

after-install::
	- ssh idevice killall TechSupport_Advanced

distclean: clean
	- rm -f $(THEOS_PROJECT_DIR)/$(PKG_ID)*.deb
	- rm -f $(THEOS_PROJECT_DIR)/.theos/packages/*
