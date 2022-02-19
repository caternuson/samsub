# The MIT License (MIT)
#
# SPDX-FileCopyrightText: Copyright (c) 2021 Carter Nelson
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# Adapted from:
# https://github.com/adafruit/circuitpython/blob/main/ports/atmel-samd/Makefile
#
# GNU Make Ref:
# https://www.gnu.org/software/make/manual/html_node/index.html
#

# Select the board to build for.
ifeq ($(BOARD),)
  $(error You must provide a BOARD parameter)
else
  ifeq ($(wildcard boards/$(BOARD)/.),)
    $(error Invalid BOARD specified)
  endif
endif

# If the build directory is not given, make it reflect the board name.
BUILD ?= build-$(BOARD)

# Load board specific configruation
include boards/$(BOARD)/configboard.mk

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# SOURCE CODE SETUP
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
INC_BASE = \
	-Iasf4_conf/$(CHIP_FAMILY)

SRC_BASE = \
	main.c

INC_ASF4 = \
	-Iasf4/$(CHIP_FAMILY) \
	-Iasf4/$(CHIP_FAMILY)/include \
	-Iasf4/$(CHIP_FAMILY)/CMSIS/Include \
	-Iasf4/$(CHIP_FAMILY)/hal/include \
	-Iasf4/$(CHIP_FAMILY)/hal/utils/include \
	-Iasf4/$(CHIP_FAMILY)/hpl/core \
	-Iasf4/$(CHIP_FAMILY)/hpl/gclk \
	-Iasf4/$(CHIP_FAMILY)/hpl/pm \
	-Iasf4/$(CHIP_FAMILY)/hpl/port \
	-Iasf4/$(CHIP_FAMILY)/hpl/sysctrl \
	-Iasf4/$(CHIP_FAMILY)/hpl/systick \
	-Iasf4/$(CHIP_FAMILY)/hri

SRC_ASF4 = \
	asf4/$(CHIP_FAMILY)/gcc/gcc/startup_$(CHIP_FAMILY).c \
	asf4/$(CHIP_FAMILY)/gcc/system_$(CHIP_FAMILY).c \
	asf4/$(CHIP_FAMILY)/hal/src/hal_init.c \
	asf4/$(CHIP_FAMILY)/hal/src/hal_io.c \
	asf4/$(CHIP_FAMILY)/hal/src/hal_atomic.c \
	asf4/$(CHIP_FAMILY)/hal/src/hal_sleep.c \
	asf4/$(CHIP_FAMILY)/hal/src/hal_gpio.c \
	asf4/$(CHIP_FAMILY)/hal/src/hal_delay.c \
	asf4/$(CHIP_FAMILY)/hal/utils/src/utils_list.c \
	asf4/$(CHIP_FAMILY)/hal/utils/src/utils_syscalls.c \
	asf4/$(CHIP_FAMILY)/hal/utils/src/utils_assert.c \
	asf4/$(CHIP_FAMILY)/hal/utils/src/utils_event.c \
	asf4/$(CHIP_FAMILY)/hpl/core/hpl_init.c \
	asf4/$(CHIP_FAMILY)/hpl/gclk/hpl_gclk.c \
	asf4/$(CHIP_FAMILY)/hpl/pm/hpl_pm.c \
	asf4/$(CHIP_FAMILY)/hpl/systick/hpl_systick.c \
	asf4/$(CHIP_FAMILY)/hpl/sysctrl/hpl_sysctrl.c \
	asf4/$(CHIP_FAMILY)/hpl/core/hpl_core_m0plus_base.c \

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Build setup
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
CC = arm-none-eabi-gcc
OBJCOPY  = arm-none-eabi-objcopy

INC = $(INC_BASE) $(INC_ASF4)
SRC = $(SRC_BASE) $(SRC_ASF4)
OBJ = $(addprefix $(BUILD)/, $(SRC:.c=.o))

TARGET_BIN   = $(BUILD)/$(BOARD).bin
TARGET_ELF   = $(BUILD)/$(BOARD).elf

COMMON_FLAGS = -mthumb -mcpu=cortex-m0plus -O0 -g3 -D__$(CHIP_VARIANT)__ -D__ARM_ARCH=6 -DCONF_DFLL_USBCRM=0
WFLAGS = -Wall
CFLAGS = -c $(COMMON_FLAGS) $(WFLAGS) $(INC)
LFLAGS = $(COMMON_FLAGS) $(WFLAGS) \
        -T$(LINKER_SCRIPT) -mfpu=vfp -mfloat-abi=softfp \
        -specs=nosys.specs -specs=nano.specs \
        -Wl,-Map,$(BUILD)/$(BOARD).map,--cref,--gc-sections

#$(info $(INC))
#$(info $(SRC))
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# R U L E S
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
STEPECHO = @echo

all: $(TARGET_BIN)

# bin is just an objcopy of elf
$(TARGET_BIN): $(TARGET_ELF)
	$(STEPECHO) "Create $@"
	$(OBJCOPY) -O binary -j .vectors -j .text -j .data $^ $@

# elf is all objs linked
$(TARGET_ELF): $(OBJ)
	$(STEPECHO) "LINK $@"
	$(CC) -o $@ $(LFLAGS) $(OBJ)

# objs are compiled from .c's
$(BUILD)/%.o: %.c
	$(STEPECHO) "CC $<"
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -c -MD -o $@ $<
