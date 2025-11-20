ORACLE_HOME ?= /opt/oracle/product/21c/dbhomeXE
CC ?= gcc
OCI_INC ?= $(shell find $(ORACLE_HOME) /usr/include/oracle -name oci.h 2>/dev/null | head -n 1)
ifeq ($(OCI_INC),)
$(error Could not find oci.h. Set ORACLE_HOME or OCI_INC to the directory containing oci.h)
endif
OCI_INC_DIR := $(dir $(OCI_INC))
CFLAGS ?= -I$(OCI_INC_DIR) -fPIC -std=c99 -Wall -Wextra
LDFLAGS ?= -L$(ORACLE_HOME)/lib -L/usr/lib/oracle/21/client64/lib -shared -lclntsh

string_udf.so: string_udf.o
	$(CC) -o $@ $< $(LDFLAGS)

string_udf.o: string_udf.c
	$(CC) $(CFLAGS) -c $<

.PHONY: clean
clean:
	rm -f string_udf.o string_udf.so
