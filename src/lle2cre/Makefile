#========================================================================
# Makefile for lle2cre.c
#
# 26-Nov-2001 T.Haran 303-492-1847  tharan@kryos.colorado.edu
# National Snow & Ice Data Center, University of Colorado, Boulder
#========================================================================
RCSID = $Header: /usr/people/haran/photoclin/src/lle2cre/Makefile,v 1.1 2001/11/20 21:55:43 haran Exp $

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
AR = ar
RANLIB = touch
CO = co
MAKEDEPEND = makedepend
INSTALL = cp
CP = cp
RM = rm -f
TAR = tar
COMPRESS = gzip

#
#	debug or optimization settings
#
#	on least significant byte first machines (Intel, Vax)
#	add -DLSB1ST option to enable byteswapping of cdb files
#
CONFIG_CFLAGS = -O
#CONFIG_CFLAGS = -DDEBUG -g
#CONFIG_CFLAGS =

#
#	libraries
#
LOCAL_LIBS = -lmaps
SYSLIBS = -lm

#
# end configuration section
#------------------------------------------------------------------------

CFLAGS = -I$(INCDIR) $(CONFIG_CFLAGS)
LIBS = -L$(LIBDIR) $(LOCAL_LIBS) $(SYSLIBS)

all : lle2cre

lle2cre: lle2cre.o
	$(CC) $(CFLAGS) -o $(BINDIR)/lle2cre lle2cre.o $(LIBS)

.SUFFIXES : .c,v .h,v

.c,v.o :
	$(CO) $<
	$(CC) $(CFLAGS) -c $*.c
	- $(RM) $*.c

.c,v.c :
	$(CO) $<

.h,v.h :
	$(CO) $<

# DO NOT DELETE THIS LINE -- make depend depends on it.

