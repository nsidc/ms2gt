#========================================================================
# Makefile for call_grids.so shareable library for calling grid
#   routines from IDL
#
# 27-Feb-2001 303-492-1847  tharan@colorado.edu
# National Snow & Ice Data Center, University of Colorado, Boulder
#========================================================================
RCSID = $Header: /data/haran/ms2gth/src/idl/grids/Makefile,v 1.6 2003/07/30 22:58:19 haran Exp haran $

#------------------------------------------------------------------------
# configuration section
#
#	installation directories
#
TOPDIR = ../../..
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
INSTALL = cp
CP = cp
RM = rm -f
TAR = tar
COMPRESS = gzip

#
#	archive file name
#
TARFILE = maps.tar

#
#	debug or optimization settings
#
#	on least significant byte first machines (Intel, Vax)
#	add -DLSB1ST option to enable byteswapping of cdb files
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
LIBS = -L$(LIBDIR) -lmaps $(SYSLIBS)
DEPEND_LIBS = $(LIBDIR)/libmaps.a
DEPEND_INCS = call_grids.h
SHL_LIBS= call_grids.$(SHL_EXT)

# The following is the default entry point. This section will determine 
# what system we are on, set the correct flags and call this same makefile
# again with the correct flags.

all : 
	@echo "OS type detected: "`uname`
	@case `uname` in \
	   "SunOS") if [  -d /proc ]; then \
			make libs \
			"SHL_EXT=so" \
			"CC=cc" \
			"C_LD=cc" \
			"CFLAGS=-K pic -fast -DSPARC -G" \
			"C_LD_FLAGS=-G -DSOLARIS" ; \
	      	    else \
	           	make libs \
			"SHL_EXT=so" \
			"CC=acc" \
			"C_LD=ld" \
			"CFLAGS=-pic -DSPARC -fsingle" \
			"C_LD_FLAGS=-assert pure-text" ; \
	   	    fi  \
		;; \
	   "HP-UX") make libs \
			"SHL_EXT=sl" \
			"CC=cc" \
			"C_LD=ld" \
			"CFLAGS=+z" \
			"C_LD_FLAGS=-b" ;; \
	   "IRIX" ) make libs \
			"SHL_EXT=so" \
			"CC=cc" \
			"C_LD=ld" \
			"CFLAGS=-KPIC" \
			"C_LD_FLAGS=-shared";; \
	   "IRIX64" ) make libs \
			"SHL_EXT=so" \
			"CC=cc" \
			"F77=@echo \"NOT Implemented for example: f77 \"" \
			"C_LD=ld" \
			"F_LD=@echo \"NOT Implemented for example: f77 \"" \
			"CFLAGS=-KPIC -ansi -n32" \
			"C_LD_FLAGS=-shared -n32";; \
	   "OSF1" )  make libs \
			"SHL_EXT=so" \
			"CC=cc -O" \
			"C_LD=ld" \
			"F_LD=ld" \
			"CFLAGS=-DOSF1" \
			"C_LD_FLAGS=-S -shared" ;; \
	   "Linux" ) make libs \
			"SHL_EXT=so" \
			"CC=cc" \
			"C_LD=ld" \
			"CFLAGS=-fPIC" \
			"C_LD_FLAGS=-shared";; \
	   *) echo "This system is not supported" ;; \
       esac

libs : $(SHL_LIBS)
	@echo ''
	@echo 'Make sure that LD_LIBRARY_PATH includes the directory'
	@echo 'that contains '$(SHL_LIBS)

# C Only libs

call_grids.$(SHL_EXT) : call_grids.o $(DEPEND_LIBS)
	$(C_LD) $(C_LD_FLAGS) -o call_grids.$(SHL_EXT) call_grids.o $(LIBS)

# Cleanup

tidy :
	rm -f *.o

clean :
	rm -f *.o *.so *.sl *.a

tar   : grids.tar.gz

grids.tar.gz:	Makefile gc.pro gch.pro test_grid_class.pro \
		Gl1250.gpd N200correct.mpp wilkins250.gpd wilkins.mpp lrsa_utm01000.gpd \
		call_grids.c call_grids.h grid_class__define.pro
	rm -f grids.tar.gz
	tar cvf grids.tar Makefile gc.pro gch.pro test_grid_class.pro \
		Gl1250.gpd N200correct.mpp wilkins250.gpd wilkins.mpp lrsa_utm01000.gpd \
		call_grids.c call_grids.h grid_class__define.pro
	gzip grids.tar

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

