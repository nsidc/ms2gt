#========================================================================
# makefile for utils
#
# 23-Nov-2004 Terry Haran tharan@colorado.edu 303-492-1847
# National Snow & Ice Data Center, University of Colorado, Boulder
#========================================================================
RCSID = $Header: /data/haran/ms2gth/src/utils/Makefile,v 1.1 2004/11/25 00:28:40 haran Exp haran $

#------------------------------------------------------------------------
# configuration section
#
#	installation directories
#
TOPDIR = ../..
LIBDIR = $(TOPDIR)/lib
INCDIR = $(TOPDIR)/include
BINDIR = $(TOPDIR)/bin

#
#	commands
#
SHELL = /bin/sh
CC = cc
CO = co
MAKEDEPEND = makedepend
INSTALL = cp
RM = rm -f
TAR = tar
COMPRESS = gzip

#
#	debug or optimization settings
#
CONFIG_CFLAGS = -O
#CONFIG_CFLAGS = -DDEBUG -g
LOCAL_CFLAGS =

#
#	libraries
#
LOCAL_LIBS = -lmapx
SYSTEM_LIBS = -lm 

#
# end configuration section
#------------------------------------------------------------------------

CFLAGS = -I$(INCDIR) $(LOCAL_CFLAGS) $(CONFIG_CFLAGS)
LIBS = -L$(LIBDIR) $(LOCAL_LIBS) $(SYSTEM_LIBS)

SRCS = extract_region.c insert_region.c make_mask.c apply_mask.c
HDRS = 

all: extract_region insert_region make_mask apply_mask install

extract_region: extract_region.o
	cc $(CFLAGS) -o extract_region extract_region.o $(LIBS)

insert_region: insert_region.o
	cc $(CFLAGS) -o insert_region insert_region.o $(LIBS)

make_mask: make_mask.o
	cc $(CFLAGS) -o make_mask make_mask.o $(LIBS)

apply_mask: apply_mask.o
	cc $(CFLAGS) -o apply_mask apply_mask.o $(LIBS)

install: extract_region insert_region make_mask apply_mask
	$(INSTALL) extract_region insert_region make_mask apply_mask $(BINDIR)

clean:
	- $(RM) $(OBJS) ll2cr

depend:
	- $(CO) $(SRCS) $(HDRS)
	$(MAKEDEPEND) -I$(INCDIR) \
		-- $(CFLAGS) -- $(SRCS)

.SUFFIXES : .c,v .h,v .x .x,v

.c,v.o :
	$(CO) $<
	$(CC) $(CFLAGS) -c $*.c
	- $(RM) $*.c

.c,v.c :
	$(CO) $<

.h,v.h :
	$(CO) $<

