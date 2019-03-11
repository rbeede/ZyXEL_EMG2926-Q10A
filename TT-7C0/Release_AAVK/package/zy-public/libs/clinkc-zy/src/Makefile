LIB = libclinkc.so

CYBER_SRC_PATH = ./src/cybergarage
IO_SRC_PATH = $(CYBER_SRC_PATH)/io
UTIL_SRC_PATH = $(CYBER_SRC_PATH)/util
NET_SRC_PATH = $(CYBER_SRC_PATH)/net
HTTP_SRC_PATH = $(CYBER_SRC_PATH)/http
SOAP_SRC_PATH = $(CYBER_SRC_PATH)/soap
UPNP_SRC_PATH = $(CYBER_SRC_PATH)/upnp
XML_SRC_PATH = $(CYBER_SRC_PATH)/xml
SSL_SRC_PATH = $(CYBER_SRC_PATH)/ssl

SOURCES += $(wildcard $(IO_SRC_PATH)/*.c)
SOURCES += $(wildcard $(UTIL_SRC_PATH)/*.c)
SOURCES += $(wildcard $(NET_SRC_PATH)/*.c)
SOURCES += $(wildcard $(HTTP_SRC_PATH)/*.c)
SOURCES += $(wildcard $(SOAP_SRC_PATH)/*.c)
SOURCES += $(wildcard $(XML_SRC_PATH)/*.c)
SOURCES += $(wildcard $(UPNP_SRC_PATH)/*.c)
SOURCES += $(wildcard $(UPNP_SRC_PATH)/control/*.c)
SOURCES += $(wildcard $(UPNP_SRC_PATH)/event/*.c)
SOURCES += $(wildcard $(UPNP_SRC_PATH)/ssdp/*.c)
SOURCES += $(wildcard $(SSL_SRC_PATH)/*.c)


OBJS = $(patsubst %.c, %.o, $(SOURCES))


#all: sanity_check $(LIB) generic_public_lib_install
all: $(LIB)

clean: 
#generic_oalclean generic_clean
	rm -rf $(OBJS)
	rm -rf $(INSTALL_DIR)/lib/public/$(LIB)
	rm $(LIB)

$(LIB): $(OBJS)
	$(CC) -shared -Wl,--whole-archive,-soname,$@ -o $@ $(OBJS) -Wl,--no-whole-archive

#
# Set our CommEngine directory (by splitting the pwd into two words
# at /userspace and taking the first word only).
# Then include the common defines under CommEngine.
# You do not need to modify this part.
#
#CURR_DIR := $(shell pwd)
#BUILD_DIR:=$(subst /userspace, /userspace,$(CURR_DIR))
#BUILD_DIR:=$(word 1, $(BUILD_DIR))

#include $(BUILD_DIR)/make.common

#CFLAGS += -DZYXEL_PATCH -DCG_USE_OPENSSL -std=gnu99

#
# Public libs are only allowed to include header files from the
# public directory.
#
# WARNING: Do not modify this section unless you understand the
# license implications of what you are doing.
#
#ALLOWED_INCLUDE_PATHS := -I.\
#                         -I$(BUILD_DIR)/userspace/public/include  \
#                         -I$(BUILD_DIR)/userspace/public/include/$(OALDIR) \
#                         -I./include/ \
#                         -I../expat/include/ \
#                         -I../openssl-0.9.7f/include

#
# Implicit rule will make the .c into a .o
# Implicit rule is $(CC) -c $(CPPFLAGS) $(CFLAGS)
# See Section 10.2 of Gnu Make manual
#
#$(LIB): $(OBJS)
#	$(CC) -shared -Wl,--whole-archive,-soname,$@ $(CFLAGS) -o $@ $(OBJS) $(CFLAGS) -Wl,--no-whole-archive



#
# Include the rule for making dependency files.
# The '-' in front of the second include suppresses
# error messages when make cannot find the .d files.
# It will just regenerate them.
# See Section 4.14 of Gnu Make.
#

#include $(BUILD_DIR)/make.deprules


