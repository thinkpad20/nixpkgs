include $(GNUSTEP_MAKEFILES)/common.make

LIBRARY_NAME = security_keychain

security_keychain_HEADER_FILES = $(notdir $(wildcard lib/*.h))
security_keychain_HEADER_FILES_DIR = lib

security_keychain_CC_FILES = \
	lib/SecIdentity.cpp lib/SecBase.cpp lib/SecTrustedApplication.cpp lib/Globals.cpp \
	lib/Certificate.cpp lib/Keychains.cpp lib/Item.cpp lib/ExtendedAttribute.cpp \
	lib/TrustedApplication.cpp lib/KeyItem.cpp lib/IdentityCursor.cpp lib/Identity.cpp

include $(GNUSTEP_MAKEFILES)/library.make
