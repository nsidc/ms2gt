#========================================================================
# Makefile for fornav.c
#
# 27-Dec-2000 T.Haran 303-492-1847  tharan@kryos.colorado.edu
# National Snow & Ice Data Center, University of Colorado, Boulder
#========================================================================
RCSID = $Header: /usr/people/haran/photoclin/src/rect2normal/Makefile,v 1.2 1999/07/28 17:47:35 haran Exp $

#------------------------------------------------------------------------
# configuration section
#
#	installation directories
#
TOPDIR = $(HOME)
LIBDIR = $(TOPDIR)/lib
INCDIR = $(TOPDIR)/include
BINDIR = ../../bin
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
#CONFIG_CFLAGS = -O
CONFIG_CFLAGS = -DDEBUG -g

#
#	system libraries
#
SYSLIBS = -lm

#
# end configuration section
#------------------------------------------------------------------------

CFLAGS = -I$(INCDIR) $(CONFIG_CFLAGS)
LIBS = -L$(LIBDIR) -lmodels $(SYSLIBS)

all : fornav

fornav: fornav.o
	$(CC) $(CFLAGS) -o $(BINDIR)/fornav fornav.o $(LIBS)

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

