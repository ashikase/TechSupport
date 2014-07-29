FRAMEWORK_NAME = TechSupport
PKG_ID = jp.ashikase.techsupport

TechSupport_OBJC_FILES = \
    lib/TSContactViewController.m \
    lib/TSHTMLViewController.m \
    lib/TSIncludeInstruction.m \
    lib/TSInstruction.m \
    lib/TSLinkInstruction.m \
    lib/TSPackage.m
TechSupport_FRAMEWORKS = MessageUI UIKit
TechSupport_LIBRARIES = lockdown
ADDITIONAL_CFLAGS = -Iinclude -include firmware.h

export ARCHS = armv6 armv7 armv7s arm64
export TARGET = iphone:clang
export TARGET_IPHONEOS_DEPLOYMENT_VERSION = 3.0

include theos/makefiles/common.mk
include $(THEOS)/makefiles/framework.mk

after-stage::
	# Remove repository-related files.
	- find $(THEOS_STAGING_DIR) -name '.gitkeep' -delete
	# Copy header files to include directory.
	- mkdir -p $(THEOS_STAGING_DIR)/Library/Frameworks/TechSupport.framework/Headers
	- cp $(THEOS_PROJECT_DIR)/include/*.h $(THEOS_STAGING_DIR)/Library/Frameworks/TechSupport.framework/Headers/

distclean: clean
	- rm -f $(THEOS_PROJECT_DIR)/$(PKG_ID)*.deb
	- rm -f $(THEOS_PROJECT_DIR)/.theos/packages/*
