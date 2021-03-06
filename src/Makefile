#========================================================================
# Makefile for ms2gt/src
#
# 13-Apr-2001 T.Haran 303-492-1847  tharan@colorado.edu
# National Snow & Ice Data Center, University of Colorado, Boulder
#========================================================================
RCSID = $Header: /data/tharan/ms2gth/src/Makefile,v 1.13 2011/03/30 19:15:52 tharan Exp tharan $

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
GCNDIR = $(SRCDIR)/grid_convert
GSZDIR = $(SRCDIR)/gridsize
IDLDIR = $(SRCDIR)/idl
LL2DIR = $(SRCDIR)/ll2cr
LLXDIR = $(SRCDIR)/ll2xy
LE2DIR = $(SRCDIR)/lle2cre
MAPDIR = $(SRCDIR)/mapx/trunk
MAPMAK = -f Makefile.ms2gt
PRJDIR = $(SRCDIR)/projection
SCTDIR = $(SRCDIR)/scripts
UTSDIR = $(SRCDIR)/utils
XY2DIR = $(SRCDIR)/xy2ll
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

all:	srcs

srcs:
	$(CD) $(MAPDIR); $(MAKE) $(MAKEFLAGS) $(CONFIG_FLAGS) $(MAPMAK) allall
	$(CD) $(GCNDIR); $(MAKE) $(MAKEFLAGS) $(CONFIG_FLAGS) all
	$(CD) $(GSZDIR); $(MAKE) $(MAKEFLAGS) $(CONFIG_FLAGS) all
	$(CD) $(LL2DIR); $(MAKE) $(MAKEFLAGS) $(CONFIG_FLAGS) all
	$(CD) $(LLXDIR); $(MAKE) $(MAKEFLAGS) $(CONFIG_FLAGS) all
	$(CD) $(LE2DIR); $(MAKE) $(MAKEFLAGS) $(CONFIG_FLAGS) all
	$(CD) $(NAVDIR); $(MAKE) $(MAKEFLAGS) $(CONFIG_FLAGS) all
	$(CD) $(PRJDIR); $(MAKE) $(MAKEFLAGS) $(CONFIG_FLAGS) all
	$(CD) $(UTSDIR); $(MAKE) $(MAKEFLAGS) $(CONFIG_FLAGS) all
	$(CD) $(XY2DIR); $(MAKE) $(MAKEFLAGS) $(CONFIG_FLAGS) all

clean:
	$(CD) $(MAPDIR); $(MAKE) $(MAKEFLAGS) $(CONFIG_FLAGS) $(MAPMAK) cleanall
	$(CD) $(GCNDIR); $(MAKE) $(MAKEFLAGS) $(CONFIG_FLAGS) clean
	$(CD) $(GSZDIR); $(MAKE) $(MAKEFLAGS) $(CONFIG_FLAGS) clean
	$(CD) $(LL2DIR); $(MAKE) $(MAKEFLAGS) $(CONFIG_FLAGS) clean
	$(CD) $(LLXDIR); $(MAKE) $(MAKEFLAGS) $(CONFIG_FLAGS) clean
	$(CD) $(LE2DIR); $(MAKE) $(MAKEFLAGS) $(CONFIG_FLAGS) clean
	$(CD) $(NAVDIR); $(MAKE) $(MAKEFLAGS) $(CONFIG_FLAGS) clean
	$(CD) $(PRJDIR); $(MAKE) $(MAKEFLAGS) $(CONFIG_FLAGS) clean
	$(CD) $(UTSDIR); $(MAKE) $(MAKEFLAGS) $(CONFIG_FLAGS) clean
	$(CD) $(XY2DIR); $(MAKE) $(MAKEFLAGS) $(CONFIG_FLAGS) clean

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

