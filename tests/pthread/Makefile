APPLICATION = pthread
include ../Makefile.tests_common

BOARD_BLACKLIST := arduino-mega2560 waspmote-pro arduino-uno arduino-duemilanove
# arduino mega2560 uno duemilanove : unknown type name: clockid_t

USEMODULE += posix
USEMODULE += pthread

include $(RIOTBASE)/Makefile.include
