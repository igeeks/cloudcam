###### --- This application
SRCS = src/cloudcam.c src/log.c src/iot.c src/s3.c
OBJS = $(SRCS:.c=.o)
PROGS = cloudcam

INCLUDE_DIRS += -I include -I config

###### --- compile/linker flags
CFLAGS += -Wall -g
#CFLAGS += -Wall -g -O2  ---- -O2 breaks mbedTLS on ARM

VENDOR_DIR = vendor

###### --- Axis ACAP app
AXIS_DIR = axis

###### --- deps
IOT_CLIENT_DIR = $(VENDOR_DIR)/aws_iot_client
MBEDTLS_DIR = $(VENDOR_DIR)/mbedtls_lib
LIBCURL_PKG = $(VENDOR_DIR)/curl-7.54.0
JANSSON_DIR = $(VENDOR_DIR)/jansson-2.9

###### --- log level control
LOG_FLAGS += -DIOT_DEBUG  # enable this for debug logs
LOG_FLAGS += -DIOT_INFO
LOG_FLAGS += -DIOT_WARN
LOG_FLAGS += -DIOT_ERROR

###### --- includes
TLS_LIB_DIR = $(MBEDTLS_DIR)/library
CURL_LIB_DIR = $(LIBCURL_PKG)/build/lib
JANSSON_LIB_DIR = $(JANSSON_DIR)/build/lib
PLATFORM_DIR = $(IOT_CLIENT_DIR)/platform/linux
PLATFORM_COMMON_DIR = $(PLATFORM_DIR)/common
PLATFORM_TLS_DIR = $(PLATFORM_DIR)/mbedtls
PLATFORM_THREAD_DIR = $(PLATFORM_DIR)/pthread
INCLUDE_DIRS += -I $(IOT_CLIENT_DIR)/include
INCLUDE_DIRS += -I $(IOT_CLIENT_DIR)/external_libs
INCLUDE_DIRS += -I $(PLATFORM_COMMON_DIR)
INCLUDE_DIRS += -I $(PLATFORM_DIR)
INCLUDE_DIRS += -I $(PLATFORM_TLS_DIR)
INCLUDE_DIRS += -I $(PLATFORM_THREAD_DIR)
INCLUDE_DIRS += -I $(MBEDTLS_DIR)/include
INCLUDE_DIRS += -I $(LIBCURL_PKG)/include
INCLUDE_DIRS += -I $(JANSSON_DIR)/build/include

###### --- link flags
TLS_LIB_FILES = -L$(TLS_LIB_DIR) -l:libmbedtls.a -l:libmbedcrypto.a -l:libmbedx509.a
LDFLAGS += -L$(CURL_LIB_DIR) -l:libcurl.a -lz
LDFLAGS += -L$(JANSSON_LIB_DIR) -l:libjansson.a
LDFLAGS += -L$(VENDOR_DIR) -laws-iot
LDFLAGS += $(TLS_LIB_FILES) -lpthread

###### --- compile flags
CFLAGS += $(INCLUDE_DIRS) $(LOG_FLAGS)

###### --- header deps
DEPS = $(SRCS:.c=.d)
DEPDIR = makedep
MAKEDEPEND ?= $(CC) -M -MT$(OBJDIR)/$*.o $(CFLAGS) -o $(DEPDIR)/$*.d $<

###### --- build cmd
BUILD = $(CC) $(CFLAGS)

###### --- targets
.PHONY:	all clean dist debug host

cloudcam: dep
	$(BUILD) -o cloudcam $(SRCS) $(LDFLAGS)
all: $(PROGS)

%.o: %.c
	@echo Compiling $<
	@$(MAKEDEPEND)
	@$(BUILD) -o $@ $< $(LDFLAGS)

clean: clean-prog clean-eap clean-target clean-vendor
clean-prog:
	rm -f $(PROGS) *.o core $(DEPDIR)

# Axis ACAP app project
clean-eap:
	$(MAKE) -C $(AXIS_DIR) clean-eap
clean-target:
	$(MAKE) -C $(AXIS_DIR) clean-target
dist:
	$(MAKE) -C $(AXIS_DIR) dist
upload:
	$(MAKE) -C $(AXIS_DIR) upload

# build for host system not axis cam
host: clean cloudcam

### vendor depdencies
dep:
	$(MAKE) -C $(VENDOR_DIR) prep
	$(MAKE) -C $(VENDOR_DIR) build
clean-vendor:
	$(MAKE) -C $(VENDOR_DIR) clean


-include $(DEPS)
