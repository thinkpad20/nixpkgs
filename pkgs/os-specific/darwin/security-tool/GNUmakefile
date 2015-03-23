include $(GNUSTEP_MAKEFILES)/common.make

TOOL_NAME = security
security_C_FILES = $(wildcard *.c)
security_CC_FILES = $(wildcard *.cpp)

security_LDFLAGS = \
	-lsecurity_cdsa_utilities -lsecurity_cdsa_utils -lsecurity_keychain -lsecurity_cssm \
	-lsecurity_cdsa_client -lsecurity_utilities -lsecurity_asn1 -framework Security \
	-framework PCSC

include $(GNUSTEP_MAKEFILES)/tool.make
