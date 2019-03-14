CROSS = arm-none-eabi-
CC = $(CROSS)gcc
LD = $(CROSS)ld
OBJDUMP = $(CROSS)objdump

DRIVERDIR = /home/ryanpatiency/fun/stm32-doc/stm32cubef4/STM32Cube_FW_F4_V1.23.0/Drivers

CFLAGS = -c -g\
	-mcpu=cortex-m4 -mfpu=fpv4-sp-d16 -mfloat-abi=hard \
	-DSTM32F429xx \
	-IInc \
	-I$(DRIVERDIR)/CMSIS/Include \
	-I$(DRIVERDIR)/STM32F4xx_HAL_Driver/Inc \
	-I$(DRIVERDIR)/CMSIS/Device/ST/STM32F4xx/Include \
	-I$(DRIVERDIR)/BSP/STM32F429I-Discovery/

TARGET = main
EXE = $(TARGET).elf
DUMP = $(TARGET).list
SRCS = $(wildcard Src/*.c) \
	$(filter-out %template.c,$(wildcard $(DRIVERDIR)/STM32F4xx_HAL_Driver/Src/*.c))

OBJS = startup.o \
	Src/system_stm32f4xx.o \
	Src/main.o \
	$(patsubst %.c,%.o,$(SRCS)) \
	$(DRIVERDIR)/BSP/STM32F429I-Discovery/stm32f429i_discovery.o

all: $(EXE)

LDFLAGS = -T flash.ld \
	-L $(shell dirname $(shell $(CC) $(CFLAGS) -print-file-name=libc.a )) \
	-L $(shell dirname $(shell $(CC) $(CFLAGS) -print-file-name=libgcc.a )) \
	-L $(shell dirname $(shell $(CC) $(CFLAGS) -print-file-name=libm.a )) \
	

$(EXE): $(OBJS)
	$(LD) -o $@ $(LDFLAGS) $^ -lc -lgcc -lm
	$(OBJDUMP) -D -S $@ > $(DUMP)

%.o: %.c
	$(CC) $(CFLAGS) -o $@ $< 

%.o: %.s
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -f $(EXE) $(DUMP) $(OBJS)

oocd:
	sudo openocd -f board/stm32f429discovery.cfg  \
		   -l /tmp/openocd.log 	\
			-c "init"                   \
		   -c "reset init"             \
		   -c "arm semihosting enable" \
		   -c "reset run"

screen:
	sudo screen /dev/ttyACM0 115200
	
gdb-oocd: $(EXE)
	arm-none-eabi-gdb $^ -ex "target remote:3333" 