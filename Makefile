#========================================================================
# Makefile for ms2gt
#
# 12-Apr-2001 T.Haran 303-492-1847  tharan@colorado.edu
# National Snow & Ice Data Center, University of Colorado, Boulder
#========================================================================
RCSID = $Header: /export/data/ms2gth/Makefile,v 1.2 2001/04/13 18:35:48 haran Exp haran $

#------------------------------------------------------------------------
# configuration section

#
#       define current version and release
#
VERSION = 00
RELEASE = 00

#
#	installation directories
#
TOPDIR = .
BINDIR = $(TOPDIR)/bin
DOCDIR = $(TOPDIR)/doc
GRDDIR = $(TOPDIR)/grids
INCDIR = $(TOPDIR)/include
LIBDIR = $(TOPDIR)/lib
SRCDIR = $(TOPDIR)/src

NAVDIR = $(SRCDIR)/fornav
GSZDIR = $(SRCDIR)/gridsize
IDLDIR = $(SRCDIR)/idl
LL2DIR = $(SRCDIR)/ll2cr
MAPDIR = $(SRCDIR)/maps
SCTDIR = $(SRCDIR)/scripts

L1BDIR = $(IDLDIR)/level1b_read
UTLDIR = $(IDLDIR)/modis_utils

#
#	installation target directories
#
TARDIR = $(TOPDIR)/ms2gt
TBINDIR = $(TARDIR)/bin
TDOCDIR = $(TARDIR)/doc
TGRDDIR = $(TARDIR)/grids
TINCDIR = $(TARDIR)/include
TLIBDIR = $(TARDIR)/lib
TSRCDIR = $(TARDIR)/src

TNAVDIR = $(TSRCDIR)/fornav
TGSZDIR = $(TSRCDIR)/gridsize
TIDLDIR = $(TSRCDIR)/idl
TLL2DIR = $(TSRCDIR)/ll2cr
TMAPDIR = $(TSRCDIR)/maps
TSCTDIR = $(TSRCDIR)/scripts

TL1BDIR = $(TIDLDIR)/level1b_read
TUTLDIR = $(TIDLDIR)/modis_utils

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
#	archive file name
#
TARFILE = $(TOPDIR)/ms2gt$(VERSION).$(RELEASE).tar

#
#	debug or optimization settings
#
#	on least significant byte first machines (Intel, Vax)
#	add -DLSB1ST option to enable byteswapping of cdb files
#
CONFIG_CFLAGS = -O
#CONFIG_CFLAGS = -DDEBUG -g

#
#	makefiles
#
SRCMAKE	= $(SRCDIR)/Makefile

#
# end configuration section
#------------------------------------------------------------------------

NAVMAKE = $(NAVDIR)/Makefile
GSZMAKE = $(GSZDIR)/Makefile
LL2MAKE = $(LL2DIR)/Makefile
MAPMAKE = $(MAPDIR)/Makefile

L1BSRCS = $(L1BDIR)/*.pro *.txt
UTLSRCS = $(UTLDIR)/*.pro

NAVSRCS = $(NAVMAKE) $(NAVDIR)/*.c
GSZSRCS = $(GSZMAKE) $(GSZDIR)/*.c
IDLSRCS = $(L1BSRCS) $(UTLSRCS)
LL2SRCS = $(LL2MAKE) $(LL2DIR)/*.c
MAPSRCS = $(MAPMAKE) $(MAPDIR)/*.c $(MAPDIR)/*.h
SCTSRCS = $(SCTDIR)/*.pl

TOPS = $(TOPDIR)/Makefile $(TOPDIR)/ms2gt_env.csh
DOCS = $(DOCDIR)/*.html
HDRS = $(INCDIR)/*.h
SRCS = $(SRCMAKE) $(NAVSRCS) $(IDLSRCS) $(LL2SRCS) $(MAPSRCS) $(SCTSRCS)

all:	srcs

srcs:
	$(CD) $(SRCDIR); $(MAKE) $(MAKEFLAGS) $(CONFIG_FLAGS) all

clean:
	$(CD) $(SRCDIR); $(MAKE) $(MAKEFLAGS) $(CONFIG_FLAGS) clean
	$(RM) $(LIBDIR)/libmaps.a

tar:
	- $(CO) $(TOPS) $(DOCS) $(HDRS) $(SRCS)
	- $(RMDIR) $(TARDIR)
	$(MKDIR) $(TARDIR)
	$(MKDIR) $(TBINDIR) $(TDOCDIR) $(TGRDDIR) $(TINCDIR) $(TLIBDIR)
	$(MKDIR) $(TSRCDIR)
	$(MKDIR) $(TNAVDIR) $(TGSZDIR) $(TLL2DIR) $(TMAPDIR) $(TSCTDIR)
	$(MKDIR) $(TIDLDIR) $(TL1BDIR) $(TUTLDIR)
	$(CP) $(TOPS) $(TARDIR)
	$(CP) $(DOCS) $(TDOCDIR)
	$(CP) $(HDRS) $(TINCDIR)
	$(CP) $(SRCMAKE) $(TSRCDIR)
	$(CP) $(NAVSRCS) $(TNAVDIR)
	$(CP) $(GSZSRCS) $(TGSZDIR)
	$(CP) $(L1BSRCS) $(TL1BDIR)
	$(CP) $(UTLSRCS) $(TUTLDIR)
	$(CP) $(LL2SRCS) $(TLL2DIR)
	$(CP) $(MAPSRCS) $(TMAPDIR)
	$(CP) $(SCTSRCS) $(TSCTDIR)
	$(TAR) cvf $(TARFILE) $(TARDIR)
	$(RM) $(TARFILE).gz
	$(COMPRESS) $(TARFILE)

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

