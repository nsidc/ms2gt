#========================================================================
# Makefile for ms2gt/src
#
# 13-Apr-2001 T.Haran 303-492-1847  tharan@colorado.edu
# National Snow & Ice Data Center, University of Colorado, Boulder
#========================================================================
RCSID = $Header: /export/data/modis/src/fornav/Makefile,v 1.4 2001/02/20 17:46:50 haran Exp $

#------------------------------------------------------------------------
# configuration section

#
#	installation directories
#
TOPDIR = ..
BINDIR = $(TOPDIR)/bin
DOCDIR = $(TOPDIR)/doc
GRDDIR = $(TOPDIR)/grids
INCDIR = $(TOPDIR)/include
LIBDIR = $(TOPDIR)/lib
SRCDIR = $(TOPDIR)/src

NAVDIR = $(SRCDIR)/fornav
IDLDIR = $(SRCDIR)/idl
LL2DIR = $(SRCDIR)/ll2cr
MAPDIR = $(SRCDIR)/maps
SCTDIR = $(SRCDIR)/scripts

L1BDIR = $(IDLDIR)/level1b_read
UTLDIR = $(IDLDIR)/modis_utils

#
#	commands
#
SHELL = /bin/sh
CC = cc
AR = ar
RANLIB = touch
CO = co
MAKE = make
MAKEDEPEND = makedepend
INSTALL = cp
CP = cp
CD = cd
RM = rm -f
RMDIR = rm -fr
MKDIR = mkdir -p
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

#
# end configuration section
#------------------------------------------------------------------------

NAVMAKE = $(NAVDIR)/Makefile
LL2MAKE = $(LL2DIR)/Makefile
MAPMAKE = $(MAPDIR)/Makefile

all:	srcs

srcs:
	$(CD) $(MAPDIR); $(MAKE) $(MAKEFLAGS) $(CONFIG_FLAGS) all; $(CD) ..
	$(CD) $(LL2DIR); $(MAKE) $(MAKEFLAGS) $(CONFIG_FLAGS) all; $(CD) ..
	$(CD) $(NAVDIR); $(MAKE) $(MAKEFLAGS) $(CONFIG_FLAGS) all; $(CD) ..

clean:
	$(CD) $(MAPDIR); $(MAKE) $(MAKEFLAGS) $(CONFIG_FLAGS) clean; $(CD) ..
	$(CD) $(LL2DIR); $(MAKE) $(MAKEFLAGS) $(CONFIG_FLAGS) clean; $(CD) ..
	$(CD) $(NAVDIR); $(MAKE) $(MAKEFLAGS) $(CONFIG_FLAGS) clean; $(CD) ..

depend:
	- $(CO) $(SRCS) $(HDRS)
	$(MAKEDEPEND) -I$(INCDIR) \
		-- $(CFLAGS) -- $(SRCS)

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

