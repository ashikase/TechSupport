FRAMEWORK_NAME = TechSupport
FRAMEWORK_ID = jp.ashikase.TechSupport

TechSupport_OBJC_FILES = \
    lib/TSContactViewController.m \
    lib/TSHTMLViewController.m \
    lib/TSIncludeInstruction.m \
    lib/TSInstruction.m \
    lib/TSLinkInstruction.m \
    lib/TSPackage.m \
    lib/TSPackageCache.m
TechSupport_FRAMEWORKS = MessageUI UIKit
TechSupport_LIBRARIES = packageinfo
ADDITIONAL_LDFLAGS = -Llib
ADDITIONAL_CFLAGS = -DFRAMEWORK_ID=\"$(FRAMEWORK_ID)\" -ICommon -Iinclude -include firmware.h -include include.pch

export ARCHS = armv6 armv7 armv7s arm64
export TARGET = iphone:clang
export TARGET_IPHONEOS_DEPLOYMENT_VERSION = 3.0

include theos/makefiles/common.mk
include $(THEOS)/makefiles/framework.mk

after-stage::
	# Copy localization files.
	- cp -a $(THEOS_PROJECT_DIR)/Localization/TechSupport/*.lproj $(THEOS_STAGING_DIR)/Library/Frameworks/TechSupport.framework/Resources/
	# Remove repository-related files.
	- find $(THEOS_STAGING_DIR) -name '.gitkeep' -delete
	# Copy header files to include directory.
	- mkdir -p $(THEOS_STAGING_DIR)/Library/Frameworks/TechSupport.framework/Headers
	- cp $(THEOS_PROJECT_DIR)/include/*.h $(THEOS_STAGING_DIR)/Library/Frameworks/TechSupport.framework/Headers/

distclean: clean
	- rm -f $(THEOS_PROJECT_DIR)/$(call lc,$(FRAMEWORK_ID))*.deb
	- rm -f $(THEOS_PROJECT_DIR)/.theos/packages/*

doc:
	- appledoc \
		--project-name $(FRAMEWORK_NAME) \
		--project-company "Lance Fetters (aka. ashikase)" \
		--company-id "jp.ashikase" \
		--exit-threshold 2 \
		--ignore "*.m" \
		--keep-intermediate-files \
		--keep-undocumented-objects \
		--keep-undocumented-members \
		--logformat xcode \
		--no-install-docset \
		--no-repeat-first-par \
		--no-warn-invalid-crossref \
		--output Documentation \
		$(THEOS_PROJECT_DIR)/include
