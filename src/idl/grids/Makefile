#========================================================================
# Makefile for call_grids.so shareable library for calling grid
#   routines from IDL
#
# 27-Feb-2001 303-492-1847  tharan@colorado.edu
# National Snow & Ice Data Center, University of Colorado, Boulder
#========================================================================
RCSID = $Header: /data/haran/ms2gth/src/idl/grids/Makefile,v 1.7 2003/07/30 23:00:14 haran Exp haran $

#------------------------------------------------------------------------
# configuration section
#
#	installation directories
#
TOPDIR = $(HOME)
#TOPDIR = ../../..
LIBDIR = $(TOPDIR)/lib
MAPDIR = $(LIBDIR)/maps
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
INSTALL = cp -f -p
MKDIR = mkdir -p
CP = cp
RM = rm -f
TAR = tar
COMPRESS = gzip

#
#	archive file name
#
TARFILE = grids.tar

#
#	debug or optimization settings
#
CONFIG_CFLAGS = -O
#CONFIG_CFLAGS = -DDEBUG -g

#
#	system libraries
#
SYSLIBS = -lm

#
# end configuration section
#------------------------------------------------------------------------

CFLAGS_EXTRA = -I$(IDL_DIR)/external -I$(INCDIR) $(CONFIG_CFLAGS)
LIBS = -L$(LIBDIR) -lmapx $(SYSLIBS)
DEPEND_LIBS = $(LIBDIR)/libmapx.a
DEPEND_INCS = call_grids.h
SHL_LIBS= call_grids.$(SHL_EXT)

# The following is the default entry point. This section will determine 
# what system we are on, set the correct flags and call this same makefile
# again with the correct flags.

all :
	@echo "OS type detected: "`uname`
	@case `uname` in \
	   "SunOS") if [  -d /proc ]; then \
			make libsinstall \
			"SHL_EXT=so" \
			"CC=cc" \
			"C_LD=cc" \
			"CFLAGS=-K pic -fast -DSPARC -G" \
			"C_LD_FLAGS=-G -DSOLARIS" ; \
	      	    else \
	           	make libsinstall \
			"SHL_EXT=so" \
			"CC=acc" \
			"C_LD=ld" \
			"CFLAGS=-pic -DSPARC -fsingle" \
			"C_LD_FLAGS=-assert pure-text" ; \
	   	    fi  \
		;; \
	   "HP-UX") make libsinstall \
			"SHL_EXT=sl" \
			"CC=cc" \
			"C_LD=ld" \
			"CFLAGS=+z" \
			"C_LD_FLAGS=-b" ;; \
	   "IRIX" ) make libsinstall \
			"SHL_EXT=so" \
			"CC=cc" \
			"C_LD=ld" \
			"CFLAGS=-KPIC" \
			"C_LD_FLAGS=-shared";; \
	   "IRIX64" ) make libsinstall \
			"SHL_EXT=so" \
			"CC=cc" \
			"F77=@echo \"NOT Implemented for example: f77 \"" \
			"C_LD=ld" \
			"F_LD=@echo \"NOT Implemented for example: f77 \"" \
			"CFLAGS=-KPIC -ansi -n32" \
			"C_LD_FLAGS=-shared -n32";; \
	   "OSF1" )  make libsinstall \
			"SHL_EXT=so" \
			"CC=cc -O" \
			"C_LD=ld" \
			"F_LD=ld" \
			"CFLAGS=-DOSF1" \
			"C_LD_FLAGS=-S -shared" ;; \
	   "Linux" ) make libsinstall \
			"SHL_EXT=so" \
			"CC=cc" \
			"C_LD=ld" \
			"CFLAGS=-fPIC" \
			"C_LD_FLAGS=-shared";; \
	   *) echo "This system is not supported" ;; \
       esac

libsinstall :	libs install

libs : $(SHL_LIBS)

install : $(SHL_LIBS)
	$(MKDIR) $(LIBDIR)
	$(INSTALL) $(SHL_LIBS) $(LIBDIR)
	@echo ''
	@echo 'Make sure that LD_LIBRARY_PATH includes '$(LIBDIR)

# C Only libs

call_grids.$(SHL_EXT) : call_grids.o $(DEPEND_LIBS)
	$(C_LD) $(C_LD_FLAGS) -o call_grids.$(SHL_EXT) call_grids.o $(LIBS)

# Cleanup

tidy :
	rm -f *.o

clean :
	rm -f *.o *.so *.sl *.a

tar :	Makefile gc.pro gch.pro test_grid_class.pro \
	call_grids.c call_grids.h grid_class__define.pro
	$(RM) $(TARFILE).gz
	$(TAR) cvf $(TARFILE) \
		Makefile gc.pro gch.pro test_grid_class.pro \
		call_grids.c call_grids.h grid_class__define.pro
	$(COMPRESS) $(TARFILE)

#  Rules for building the object files.

.SUFFIXES : .c,v .h,v

.c.o:	$(DEPEND_INCS)
	$(CC) $(CFLAGS) $(CFLAGS_EXTRA)	-c $*.c

.c,v.o :
	$(CO) $<
	$(CC) $(CFLAGS) $(CFLAGS_EXTRA)	-c $*.c
	- $(RM) $*.c

.c,v.c :
	$(CO) $<

.h,v.h :
	$(CO) $<

# DO NOT DELETE THIS LINE -- make depend depends on it.

