#
# Makefile generated by fpcmake v1.00 [2000/07/11]
#

defaultrule: all

#####################################################################
# Autodetect OS (Linux or Dos or Windows NT)
# define inlinux when running under linux
# define inWinNT when running under WinNT
#####################################################################

# We need only / in the path
override PATH:=$(subst \,/,$(PATH))

# Search for PWD and determine also if we are under linux
PWD:=$(strip $(wildcard $(addsuffix /pwd.exe,$(subst ;, ,$(PATH)))))
ifeq ($(PWD),)
PWD:=$(strip $(wildcard $(addsuffix /pwd,$(subst :, ,$(PATH)))))
ifeq ($(PWD),)
nopwd:
	@echo You need the GNU utils package to use this Makefile!
	@echo Get ftp://ftp.freepascal.org/pub/fpc/dist/go32v2/utilgo32.zip
	@exit
else
inlinux=1
endif
else
PWD:=$(firstword $(PWD))
endif

# Detect NT - NT sets OS to Windows_NT
ifndef inlinux
ifeq ($(OS),Windows_NT)
inWinNT=1
endif
endif

# Detect OS/2 - OS/2 has OS2_SHELL defined
ifndef inlinux
ifndef inWinNT
ifdef OS2_SHELL
inOS2=1
endif
endif
endif

# The extension of executables
ifdef inlinux
EXEEXT=
else
EXEEXT=.exe
endif

# The path which is searched separated by spaces
ifdef inlinux
SEARCHPATH=$(subst :, ,$(PATH))
else
SEARCHPATH=$(subst ;, ,$(PATH))
endif

# Base dir
ifdef PWD
BASEDIR:=$(shell $(PWD))
else
BASEDIR=.
endif

#####################################################################
# FPC version/target Detection
#####################################################################

# What compiler to use ?
ifndef FPC
# Compatibility with old makefiles
ifdef PP
FPC=$(PP)
else
ifdef inOS2
FPC=ppos2
else
FPC=ppc386
endif
endif
endif
override FPC:=$(subst $(EXEEXT),,$(FPC))
override FPC:=$(subst \,/,$(FPC))$(EXEEXT)

# Target OS
ifndef OS_TARGET
OS_TARGET:=$(shell $(FPC) -iTO)
endif

# Source OS
ifndef OS_SOURCE
OS_SOURCE:=$(shell $(FPC) -iSO)
endif

# Target CPU
ifndef CPU_TARGET
CPU_TARGET:=$(shell $(FPC) -iTP)
endif

# Source CPU
ifndef CPU_SOURCE
CPU_SOURCE:=$(shell $(FPC) -iSP)
endif

# FPC version
ifndef FPC_VERSION
FPC_VERSION:=$(shell $(FPC) -iV)
endif

export FPC OS_TARGET OS_SOURCE CPU_TARGET CPU_SOURCE FPC_VERSION

#####################################################################
# Pre Settings
#####################################################################

ifndef LCLPLATFORM
LCLPLATFORM=gtk
endif
#####################################################################
# FPCDIR Setting
#####################################################################

# Test FPCDIR to look if the RTL dir exists
ifdef FPCDIR
override FPCDIR:=$(subst \,/,$(FPCDIR))
ifeq ($(wildcard $(FPCDIR)/rtl),)
ifeq ($(wildcard $(FPCDIR)/units),)
override FPCDIR=wrong
endif
endif
else
override FPCDIR=wrong
endif

# Detect FPCDIR
ifeq ($(FPCDIR),wrong)
ifdef inlinux
override FPCDIR=/usr/local/lib/fpc/$(FPC_VERSION)
ifeq ($(wildcard $(FPCDIR)/units),)
override FPCDIR=/usr/lib/fpc/$(FPC_VERSION)
endif
else
override FPCDIR:=$(subst /$(FPC),,$(firstword $(strip $(wildcard $(addsuffix /$(FPC),$(SEARCHPATH))))))
override FPCDIR:=$(FPCDIR)/..
ifeq ($(wildcard $(FPCDIR)/rtl),)
ifeq ($(wildcard $(FPCDIR)/units),)
override FPCDIR:=$(FPCDIR)/..
ifeq ($(wildcard $(FPCDIR)/rtl),)
ifeq ($(wildcard $(FPCDIR)/units),)
override FPCDIR=c:/pp
endif
endif
endif
endif
endif
endif

ifndef PACKAGESDIR
PACKAGESDIR=$(FPCDIR)/packages
endif
ifndef TOOLKITSDIR
TOOLKITSDIR=
endif
ifndef COMPONENTSDIR
COMPONENTSDIR=
endif

# Create units dir
ifneq ($(FPCDIR),.)
UNITSDIR=$(FPCDIR)/units/$(OS_TARGET)
endif

#####################################################################
# User Settings
#####################################################################


# Targets

override EXEOBJECTS+=allunits

# Clean

override EXTRACLEANUNITS+=$(basename $(wildcard $(UNITTARGETDIR)/*$(PPUEXT)))
override EXTRACLEANFILES+=$(wildcard $(UNITTARGETDIR)/*$(OEXT))

# Install

ZIPTARGET=install

# Defaults


# Directories

override NEEDUNITDIR=$(UNITTARGETDIR) . ./interfaces/$(LCLPLATFORM)
override NEEDINCDIR=./include ./interfaces/$(LCLPLATFORM)
ifndef UNITTARGETDIR
UNITTARGETDIR=./units
endif

# Packages

override PACKAGES+=rtl fcl gtk

# Libraries


# Info

INFOTARGET=fpc_infocfg fpc_infoobjects fpc_infoinstall 

#####################################################################
# Shell tools
#####################################################################

# echo
ifndef ECHO
ECHO:=$(strip $(wildcard $(addsuffix /gecho$(EXEEXT),$(SEARCHPATH))))
ifeq ($(ECHO),)
ECHO:=$(strip $(wildcard $(addsuffix /echo$(EXEEXT),$(SEARCHPATH))))
ifeq ($(ECHO),)
ECHO:=echo
ECHOE:=echo
else
ECHO:=$(firstword $(ECHO))
ECHOE=$(ECHO) -E
endif
else
ECHO:=$(firstword $(ECHO))
ECHOE=$(ECHO) -E
endif
endif

# To copy pograms
ifndef COPY
COPY:=cp -fp
endif

# Copy a whole tree
ifndef COPYTREE
COPYTREE:=cp -rfp
endif

# To move pograms
ifndef MOVE
MOVE:=mv -f
endif

# Check delete program
ifndef DEL
DEL:=rm -f
endif

# Check deltree program
ifndef DELTREE
DELTREE:=rm -rf
endif

# To install files
ifndef INSTALL
ifdef inlinux
INSTALL:=install -m 644
else
INSTALL:=$(COPY)
endif
endif

# To install programs
ifndef INSTALLEXE
ifdef inlinux
INSTALLEXE:=install -m 755
else
INSTALLEXE:=$(COPY)
endif
endif

# To make a directory.
ifndef MKDIR
ifdef inlinux
MKDIR:=install -m 755 -d
else
MKDIR:=ginstall -m 755 -d
endif
endif

export ECHO ECHOE COPY COPYTREE MOVE DEL DELTREE INSTALL INSTALLEXE MKDIR

#####################################################################
# Default Tools
#####################################################################

# assembler, redefine it if cross compiling
ifndef AS
AS=as
endif

# linker, but probably not used
ifndef LD
LD=ld
endif

# ppas.bat / ppas.sh
ifdef inlinux
PPAS=ppas.sh
else
ifdef inOS2
PPAS=ppas.cmd
else
PPAS=ppas.bat
endif
endif

# ldconfig to rebuild .so cache
ifdef inlinux
LDCONFIG=ldconfig
else
LDCONFIG=
endif

# ppumove
ifndef PPUMOVE
PPUMOVE:=$(strip $(wildcard $(addsuffix /ppumove$(EXEEXT),$(SEARCHPATH))))
ifeq ($(PPUMOVE),)
PPUMOVE=
else
PPUMOVE:=$(firstword $(PPUMOVE))
endif
endif
export PPUMOVE

# ppufiles
ifndef PPUFILES
PPUFILES:=$(strip $(wildcard $(addsuffix /ppufiles$(EXEEXT),$(SEARCHPATH))))
ifeq ($(PPUFILES),)
PPUFILES=
else
PPUFILES:=$(firstword $(PPUFILES))
endif
endif
export PPUFILES

# Look if UPX is found for go32v2 and win32. We can't use $UPX becuase
# upx uses that one itself (PFV)
ifndef UPXPROG
ifeq ($(OS_TARGET),go32v2)
UPXPROG:=1
endif
ifeq ($(OS_TARGET),win32)
UPXPROG:=1
endif
ifdef UPXPROG
UPXPROG:=$(strip $(wildcard $(addsuffix /upx$(EXEEXT),$(SEARCHPATH))))
ifeq ($(UPXPROG),)
UPXPROG=
else
UPXPROG:=$(firstword $(UPXPROG))
endif
else
UPXPROG=
endif
endif
export UPXPROG

# ZipProg, you can't use Zip as the var name (PFV)
ifndef ZIPPROG
ZIPPROG:=$(strip $(wildcard $(addsuffix /zip$(EXEEXT),$(SEARCHPATH))))
ifeq ($(ZIPPROG),)
ZIPPROG=
else
ZIPPROG:=$(firstword $(ZIPPROG))
endif
endif
export ZIPPROG

ZIPOPT=-9
ZIPEXT=.zip

# Tar
ifndef TARPROG
TARPROG:=$(strip $(wildcard $(addsuffix /tar$(EXEEXT),$(SEARCHPATH))))
ifeq ($(TARPROG),)
TARPROG=
else
TARPROG:=$(firstword $(TARPROG))
endif
endif
export TARPROG

ifeq ($(USETAR),bz2)
TAROPT=vI
TAREXT=.tar.bz2
else
TAROPT=vz
TAREXT=.tar.gz
endif

#####################################################################
# Default extensions
#####################################################################

# Default needed extensions (Go32v2,Linux)
LOADEREXT=.as
PPLEXT=.ppl
PPUEXT=.ppu
OEXT=.o
ASMEXT=.s
SMARTEXT=.sl
STATICLIBEXT=.a
SHAREDLIBEXT=.so
RSTEXT=.rst
FPCMADE=fpcmade

# Go32v1
ifeq ($(OS_TARGET),go32v1)
PPUEXT=.pp1
OEXT=.o1
ASMEXT=.s1
SMARTEXT=.sl1
STATICLIBEXT=.a1
SHAREDLIBEXT=.so1
FPCMADE=fpcmade.v1
endif

# Go32v2
ifeq ($(OS_TARGET),go32v2)
FPCMADE=fpcmade.dos
endif

# Linux
ifeq ($(OS_TARGET),linux)
FPCMADE=fpcmade.lnx
endif

# Win32
ifeq ($(OS_TARGET),win32)
PPUEXT=.ppw
OEXT=.ow
ASMEXT=.sw
SMARTEXT=.slw
STATICLIBEXT=.aw
SHAREDLIBEXT=.dll
FPCMADE=fpcmade.w32
endif

# OS/2
ifeq ($(OS_TARGET),os2)
PPUEXT=.ppo
ASMEXT=.so2
OEXT=.oo2
SMARTEXT=.so
STATICLIBEXT=.ao2
SHAREDLIBEXT=.dll
FPCMADE=fpcmade.os2
endif

# library prefix
LIBPREFIX=lib
ifeq ($(OS_TARGET),go32v2)
LIBPREFIX=
endif
ifeq ($(OS_TARGET),go32v1)
LIBPREFIX=
endif

# determine which .pas extension is used
ifndef PASEXT
ifdef EXEOBJECTS
override TESTPAS:=$(strip $(wildcard $(addsuffix .pas,$(firstword $(EXEOBJECTS)))))
else
override TESTPAS:=$(strip $(wildcard $(addsuffix .pas,$(firstword $(UNITOBJECTS)))))
endif
ifeq ($(TESTPAS),)
PASEXT=.pp
else
PASEXT=.pas
endif
endif


# Check if the dirs really exists, else turn it off
ifeq ($(wildcard $(UNITSDIR)),)
UNITSDIR=
endif
ifeq ($(wildcard $(TOOLKITSDIR)),)
TOOLKITSDIR=
endif
ifeq ($(wildcard $(PACKAGESDIR)),)
PACKAGESDIR=
endif
ifeq ($(wildcard $(COMPONENTSDIR)),)
COMPONENTSDIR=
endif


# PACKAGESDIR packages

PACKAGERTL=1
PACKAGEFCL=1
PACKAGEGTK=1

ifdef PACKAGERTL
ifneq ($(wildcard $(FPCDIR)/rtl),)
ifneq ($(wildcard $(FPCDIR)/rtl/$(OS_TARGET)),)
PACKAGEDIR_RTL=$(FPCDIR)/rtl/$(OS_TARGET)
else
PACKAGEDIR_RTL=$(FPCDIR)/rtl
endif
ifeq ($(wildcard $(PACKAGEDIR_RTL)/$(FPCMADE)),)
override COMPILEPACKAGES+=package_rtl
package_rtl:
	$(MAKE) -C $(PACKAGEDIR_RTL) all
endif
UNITDIR_RTL=$(PACKAGEDIR_RTL)
else
PACKAGEDIR_RTL=
ifneq ($(wildcard $(UNITSDIR)/rtl),)
ifneq ($(wildcard $(UNITSDIR)/rtl/$(OS_TARGET)),)
UNITDIR_RTL=$(UNITSDIR)/rtl/$(OS_TARGET)
else
UNITDIR_RTL=$(UNITSDIR)/rtl
endif
else
UNITDIR_RTL=
endif
endif
ifdef UNITDIR_RTL
override NEEDUNITDIR+=$(UNITDIR_RTL)
endif
endif
ifdef PACKAGEFCL
ifneq ($(wildcard $(FPCDIR)/fcl),)
ifneq ($(wildcard $(FPCDIR)/fcl/$(OS_TARGET)),)
PACKAGEDIR_FCL=$(FPCDIR)/fcl/$(OS_TARGET)
else
PACKAGEDIR_FCL=$(FPCDIR)/fcl
endif
ifeq ($(wildcard $(PACKAGEDIR_FCL)/$(FPCMADE)),)
override COMPILEPACKAGES+=package_fcl
package_fcl:
	$(MAKE) -C $(PACKAGEDIR_FCL) all
endif
UNITDIR_FCL=$(PACKAGEDIR_FCL)
else
PACKAGEDIR_FCL=
ifneq ($(wildcard $(UNITSDIR)/fcl),)
ifneq ($(wildcard $(UNITSDIR)/fcl/$(OS_TARGET)),)
UNITDIR_FCL=$(UNITSDIR)/fcl/$(OS_TARGET)
else
UNITDIR_FCL=$(UNITSDIR)/fcl
endif
else
UNITDIR_FCL=
endif
endif
ifdef UNITDIR_FCL
override NEEDUNITDIR+=$(UNITDIR_FCL)
endif
endif
ifdef PACKAGEGTK
ifneq ($(wildcard $(PACKAGESDIR)/gtk),)
ifneq ($(wildcard $(PACKAGESDIR)/gtk/$(OS_TARGET)),)
PACKAGEDIR_GTK=$(PACKAGESDIR)/gtk/$(OS_TARGET)
else
PACKAGEDIR_GTK=$(PACKAGESDIR)/gtk
endif
ifeq ($(wildcard $(PACKAGEDIR_GTK)/$(FPCMADE)),)
override COMPILEPACKAGES+=package_gtk
package_gtk:
	$(MAKE) -C $(PACKAGEDIR_GTK) all
endif
UNITDIR_GTK=$(PACKAGEDIR_GTK)
else
PACKAGEDIR_GTK=
ifneq ($(wildcard $(UNITSDIR)/gtk),)
ifneq ($(wildcard $(UNITSDIR)/gtk/$(OS_TARGET)),)
UNITDIR_GTK=$(UNITSDIR)/gtk/$(OS_TARGET)
else
UNITDIR_GTK=$(UNITSDIR)/gtk
endif
else
UNITDIR_GTK=
endif
endif
ifdef UNITDIR_GTK
override NEEDUNITDIR+=$(UNITDIR_GTK)
endif
endif


#####################################################################
# Default Directories
#####################################################################

# set the prefix directory where to install everything
ifndef PREFIXINSTALLDIR
ifdef inlinux
PREFIXINSTALLDIR=/usr
else
PREFIXINSTALLDIR=/pp
endif
endif
export PREFIXINSTALLDIR

# Where to place the resulting zip files
ifndef DESTZIPDIR
DESTZIPDIR:=$(BASEDIR)
endif
export DESTZIPDIR

#####################################################################
# Install Directories
#####################################################################

# set the base directory where to install everything
ifndef BASEINSTALLDIR
ifdef inlinux
BASEINSTALLDIR=$(PREFIXINSTALLDIR)/lib/fpc/$(FPC_VERSION)
else
BASEINSTALLDIR=$(PREFIXINSTALLDIR)
endif
endif

# set the directory where to install the binaries
ifndef BININSTALLDIR
ifdef inlinux
BININSTALLDIR=$(PREFIXINSTALLDIR)/bin
else
BININSTALLDIR=$(BASEINSTALLDIR)/bin/$(OS_TARGET)
endif
endif

# set the directory where to install the units.
ifndef UNITINSTALLDIR
UNITINSTALLDIR=$(BASEINSTALLDIR)/units/$(OS_TARGET)
ifdef UNITSUBDIR
UNITINSTALLDIR:=$(UNITINSTALLDIR)/$(UNITSUBDIR)
endif
endif

# Where to install shared libraries
ifndef LIBINSTALLDIR
ifdef inlinux
LIBINSTALLDIR=$(PREFIXINSTALLDIR)/lib
else
LIBINSTALLDIR=$(UNITINSTALLDIR)
endif
endif

# Where the source files will be stored
ifndef SOURCEINSTALLDIR
ifdef inlinux
SOURCEINSTALLDIR=$(PREFIXINSTALLDIR)/src/fpc-$(FPC_VERSION)
else
SOURCEINSTALLDIR=$(BASEINSTALLDIR)/source
endif
ifdef SOURCESUBDIR
SOURCEINSTALLDIR:=$(SOURCEINSTALLDIR)/$(SOURCESUBDIR)
endif
endif

# Where the doc files will be stored
ifndef DOCINSTALLDIR
ifdef inlinux
DOCINSTALLDIR=$(PREFIXINSTALLDIR)/doc/fpc-$(FPC_VERSION)
else
DOCINSTALLDIR=$(BASEINSTALLDIR)/doc
endif
endif

# Where to install the examples, under linux we use the doc dir
# because the copytree command will create a subdir itself
ifndef EXAMPLEINSTALLDIR
ifdef inlinux
EXAMPLEINSTALLDIR=$(DOCINSTALLDIR)/examples
else
EXAMPLEINSTALLDIR=$(BASEINSTALLDIR)/examples
endif
ifdef EXAMPLESUBDIR
EXAMPLEINSTALLDIR:=$(EXAMPLEINSTALLDIR)/$(EXAMPLESUBDIR)
endif
endif

# Where the some extra (data)files will be stored
ifndef DATAINSTALLDIR
DATAINSTALLDIR=$(BASEINSTALLDIR)
endif

#####################################################################
# Redirection
#####################################################################

ifndef REDIRFILE
REDIRFILE=log
endif

ifdef REDIR
ifndef inlinux
override FPC=redir -eo $(FPC)
endif
# set the verbosity to max
override FPCOPT+=-va
override REDIR:= >> $(REDIRFILE)
endif


#####################################################################
# Compiler Command Line
#####################################################################

# Load commandline OPTDEF and add FPC_CPU define
override FPCOPTDEF:=-d$(CPU_TARGET)

# Load commandline OPT and add target and unit dir to be sure
ifneq ($(OS_TARGET),$(OS_SOURCE))
override FPCOPT+=-T$(OS_TARGET)
endif

# User dirs should be first, so they are looked at first
ifdef UNITDIR
override FPCOPT+=$(addprefix -Fu,$(UNITDIR))
endif
ifdef LIBDIR
override FPCOPT+=$(addprefix -Fl,$(LIBDIR))
endif
ifdef OBJDIR
override FPCOPT+=$(addprefix -Fo,$(OBJDIR))
endif
ifdef INCDIR
override FPCOPT+=$(addprefix -Fi,$(INCDIR))
endif

# Smartlinking
ifdef LINKSMART
override FPCOPT+=-XX
endif

# Smartlinking creation
ifdef CREATESMART
override FPCOPT+=-CX
endif

# Debug
ifdef DEBUG
override FPCOPT+=-g -dDEBUG
endif

# Release mode (strip, optimize and don't load ppc386.cfg)
# 0.99.12b has a bug in the optimizer so don't use it by default
ifdef RELEASE
ifeq ($(FPC_VERSION),0.99.12)
override FPCOPT+=-Xs -OGp3 -n
else
override FPCOPT+=-Xs -OG2p3 -n
endif
endif

# Strip
ifdef STRIP
override FPCOPT+=-Xs
endif

# Optimizer
ifdef OPTIMIZE
override FPCOPT+=-OG2p3
endif

# Verbose settings (warning,note,info)
ifdef VERBOSE
override FPCOPT+=-vwni
endif

ifdef NEEDUNITDIR
override FPCOPT+=$(addprefix -Fu,$(NEEDUNITDIR))
endif

ifdef UNITSDIR
override FPCOPT+=-Fu$(UNITSDIR)
endif

ifdef NEEDINCDIR
override FPCOPT+=$(addprefix -Fi,$(NEEDINCDIR))
endif


ifdef UNITTARGETDIR
override FPCOPT+=-FU$(UNITTARGETDIR)
endif

# Add commandline options last so they can override
ifdef OPT
override FPCOPT+=$(OPT)
endif

# Add defines from FPCOPTDEF to FPCOPT
ifdef FPCOPTDEF
override FPCOPT+=$(FPCOPTDEF)
endif

# Error file ?
ifdef ERRORFILE
override FPCOPT+=-Fr$(ERRORFILE)
endif

# Was a config file specified ?
ifdef CFGFILE
override FPCOPT+=@$(CFGFILE)
endif

# For win32 the options are passed using the environment FPCEXTCMD
ifeq ($(OS_SOURCE),win32)
override FPCEXTCMD:=$(FPCOPT)
override FPCOPT:=!FPCEXTCMD
export FPCEXTCMD
endif

# Compiler commandline
override COMPILER:=$(FPC) $(FPCOPT)

# also call ppas if with command option -s
ifeq (,$(findstring -s ,$(COMPILER)))
EXECPPAS=
else
EXECPPAS:=@$(PPAS)
endif

#####################################################################
# Standard rules
#####################################################################

debug: fpc_debug

smart: fpc_smart

shared: fpc_shared

showinstall: fpc_showinstall

install: fpc_install

sourceinstall: fpc_sourceinstall

exampleinstall: fpc_exampleinstall

zipinstall: fpc_zipinstall

zipsourceinstall: fpc_zipsourceinstall

zipexampleinstall: fpc_zipexampleinstall

clean: fpc_clean

distclean: fpc_distclean

cleanall: fpc_cleanall

info: fpc_info

.PHONY:  debug smart shared showinstall install sourceinstall exampleinstall zipinstall zipsourceinstall zipexampleinstall clean distclean cleanall info

#####################################################################
# Exes
#####################################################################

.PHONY: fpc_exes

ifdef EXEOBJECTS
override EXEFILES=$(addsuffix $(EXEEXT),$(EXEOBJECTS))
override EXEOFILES=$(addsuffix $(OEXT),$(EXEOBJECTS))

override ALLTARGET+=fpc_exes
override INSTALLEXEFILES+=$(EXEFILES)
override CLEANEXEFILES+=$(EXEFILES) $(EXEOFILES)
endif

fpc_exes: $(EXEFILES)

#####################################################################
# General compile rules
#####################################################################

.PHONY: fpc_packages fpc_all fpc_debug

$(FPCMADE): $(ALLTARGET)
	@$(ECHO) Compiled > $(FPCMADE)

fpc_packages: $(COMPILEPACKAGES)

fpc_all: fpc_packages $(FPCMADE)

fpc_debug:
	$(MAKE) all DEBUG=1

# General compile rules, available for both possible PASEXT

.SUFFIXES: $(EXEEXT) $(PPUEXT) $(OEXT) .pas .pp

%$(PPUEXT): %.pp
	$(COMPILER) $< $(REDIR)
	$(EXECPPAS)

%$(PPUEXT): %.pas
	$(COMPILER) $< $(REDIR)
	$(EXECPPAS)

%$(EXEEXT): %.pp
	$(COMPILER) $< $(REDIR)
	$(EXECPPAS)

%$(EXEEXT): %.pas
	$(COMPILER) $< $(REDIR)
	$(EXECPPAS)

#####################################################################
# Library
#####################################################################

.PHONY: fpc_smart fpc_shared

ifdef LIBVERSION
LIBFULLNAME=$(LIBNAME).$(LIBVERSION)
else
LIBFULLNAME=$(LIBNAME)
endif

# Default sharedlib units are all unit objects
ifndef SHAREDLIBUNITOBJECTS
SHAREDLIBUNITOBJECTS:=$(UNITOBJECTS)
endif

fpc_smart:
	$(MAKE) all LINKSMART=1 CREATESMART=1

fpc_shared: all
ifdef inlinux
ifndef LIBNAME
	@$(ECHO) "LIBNAME not set"
else
	$(PPUMOVE) $(SHAREDLIBUNITOBJECTS) -o$(LIBFULLNAME)
endif
else
	@$(ECHO) "Shared Libraries not supported"
endif

#####################################################################
# Install rules
#####################################################################

.PHONY: fpc_showinstall fpc_install

ifdef EXTRAINSTALLUNITS
override INSTALLPPUFILES+=$(addsuffix $(PPUEXT),$(EXTRAINSTALLUNITS))
endif

ifdef INSTALLPPUFILES
ifdef PPUFILES
INSTALLPPULINKFILES:=$(shell $(PPUFILES) -S -O $(INSTALLPPUFILES))
else
INSTALLPPULINKFILES:=$(wildcard $(subst $(PPUEXT),$(OEXT),$(INSTALLPPUFILES)))
endif
endif

fpc_showinstall: $(SHOWINSTALLTARGET)
ifdef INSTALLEXEFILES
	@$(ECHO) -e $(addprefix "\n"$(BININSTALLDIR)/,$(INSTALLEXEFILES))
endif
ifdef INSTALLPPUFILES
	@$(ECHO) -e $(addprefix "\n"$(UNITINSTALLDIR)/,$(INSTALLPPUFILES))
ifneq ($(INSTALLPPULINKFILES),)
	@$(ECHO) -e $(addprefix "\n"$(UNITINSTALLDIR)/,$(INSTALLPPULINKFILES))
endif
ifneq ($(wildcard $(LIBFULLNAME)),)
	@$(ECHO) $(LIBINSTALLDIR)/$(LIBFULLNAME)
ifdef inlinux
	@$(ECHO) $(LIBINSTALLDIR)/$(LIBNAME)
endif
endif
endif
ifdef EXTRAINSTALLFILES
	@$(ECHO) -e $(addprefix "\n"$(DATAINSTALLDIR)/,$(EXTRAINSTALLFILES))
endif

fpc_install: $(INSTALLTARGET)
# Create UnitInstallFiles
ifdef INSTALLEXEFILES
	$(MKDIR) $(BININSTALLDIR)
# Compress the exes if upx is defined
ifdef UPXPROG
	-$(UPXPROG) $(INSTALLEXEFILES)
endif
	$(INSTALLEXE) $(INSTALLEXEFILES) $(BININSTALLDIR)
endif
ifdef INSTALLPPUFILES
	$(MKDIR) $(UNITINSTALLDIR)
	$(INSTALL) $(INSTALLPPUFILES) $(UNITINSTALLDIR)
ifneq ($(INSTALLPPULINKFILES),)
	$(INSTALL) $(INSTALLPPULINKFILES) $(UNITINSTALLDIR)
endif
ifneq ($(wildcard $(LIBFULLNAME)),)
	$(MKDIR) $(LIBINSTALLDIR)
	$(INSTALL) $(LIBFULLNAME) $(LIBINSTALLDIR)
ifdef inlinux
	ln -sf $(LIBFULLNAME) $(LIBINSTALLDIR)/$(LIBNAME)
endif
endif
endif
ifdef EXTRAINSTALLFILES
	$(MKDIR) $(DATAINSTALLDIR)
	$(INSTALL) $(EXTRAINSTALLFILES) $(DATAINSTALLDIR)
endif

#####################################################################
# SourceInstall rules
#####################################################################

.PHONY: fpc_sourceinstall

ifndef SOURCETOPDIR
SOURCETOPDIR=$(BASEDIR)
endif

fpc_sourceinstall: clean
	$(MKDIR) $(SOURCEINSTALLDIR)
	$(COPYTREE) $(SOURCETOPDIR) $(SOURCEINSTALLDIR)

#####################################################################
# exampleinstall rules
#####################################################################

.PHONY: fpc_exampleinstall

fpc_exampleinstall: $(addsuffix _clean,$(EXAMPLEDIROBJECTS))
ifdef EXAMPLESOURCEFILES
	$(MKDIR) $(EXAMPLEINSTALLDIR)
	$(COPY) $(EXAMPLESOURCEFILES) $(EXAMPLEINSTALLDIR)
endif
ifdef EXAMPLEDIROBJECTS
ifndef EXAMPLESOURCEFILES
	$(MKDIR) $(EXAMPLEINSTALLDIR)
endif
	$(COPYTREE) $(addsuffix /*,$(EXAMPLEDIROBJECTS)) $(EXAMPLEINSTALLDIR)
endif

#####################################################################
# Zip
#####################################################################

.PHONY: fpc_zipinstall

# Create suffix to add
ifndef PACKAGESUFFIX
PACKAGESUFFIX=$(OS_TARGET)
ifeq ($(OS_TARGET),go32v2)
PACKAGESUFFIX=go32
endif
ifeq ($(OS_TARGET),win32)
PACKAGESUFFIX=w32
endif
endif

# Temporary path to pack a file
ifndef PACKDIR
ifndef inlinux
PACKDIR=$(BASEDIR)/pack_tmp
else
PACKDIR=/tmp/fpc-pack
endif
endif

# Maybe create default zipname from packagename
ifndef ZIPNAME
ifdef PACKAGENAME
ZIPNAME=$(PACKAGEPREFIX)$(PACKAGENAME)$(PACKAGESUFFIX)
endif
endif

# Use tar by default under linux
ifndef USEZIP
ifdef inlinux
USETAR=1
endif
endif

fpc_zipinstall:
ifndef ZIPNAME
	@$(ECHO) "Please specify ZIPNAME!"
	@exit 1
else
	$(MAKE) $(ZIPTARGET) PREFIXINSTALLDIR=$(PACKDIR)
ifdef USETAR
	$(DEL) $(DESTZIPDIR)/$(ZIPNAME)$(TAREXT)
	cd $(PACKDIR) ; $(TARPROG) c$(TAROPT) --file $(DESTZIPDIR)/$(ZIPNAME)$(TAREXT) * ; cd $(BASEDIR)
else
	$(DEL) $(DESTZIPDIR)/$(ZIPNAME)$(ZIPEXT)
	cd $(PACKDIR) ; $(ZIPPROG) -Dr $(ZIPOPT) $(DESTZIPDIR)/$(ZIPNAME)$(ZIPEXT) * ; cd $(BASEDIR)
endif
	$(DELTREE) $(PACKDIR)
endif

.PHONY:  fpc_zipsourceinstall

fpc_zipsourceinstall:
	$(MAKE) fpc_zipinstall ZIPTARGET=sourceinstall PACKAGESUFFIX=src

.PHONY:  fpc_zipexampleinstall

fpc_zipexampleinstall:
	$(MAKE) fpc_zipinstall ZIPTARGET=exampleinstall PACKAGESUFFIX=exm

#####################################################################
# Clean rules
#####################################################################

.PHONY: fpc_clean fpc_cleanall fpc_distclean

ifdef EXTRACLEANUNITS
override CLEANPPUFILES+=$(addsuffix $(PPUEXT),$(EXTRACLEANUNITS))
endif

ifdef CLEANPPUFILES
ifdef PPUFILES
CLEANPPULINKFILES:=$(shell $(PPUFILES) $(CLEANPPUFILES))
else
CLEANPPULINKFILES:=$(wildcard $(subst $(PPUEXT),$(OEXT),$(CLEANPPUFILES)))
endif
endif

fpc_clean: $(CLEANTARGET)
ifdef CLEANEXEFILES
	-$(DEL) $(CLEANEXEFILES)
endif
ifdef CLEANPPUFILES
	-$(DEL) $(CLEANPPUFILES)
endif
ifneq ($(CLEANPPULINKFILES),)
	-$(DEL) $(CLEANPPULINKFILES)
endif
ifdef CLEANRSTFILES
	-$(DEL) $(CLEANRSTFILES)
endif
ifdef EXTRACLEANFILES
	-$(DEL) $(EXTRACLEANFILES)
endif
ifdef LIBNAME
	-$(DEL) $(LIBNAME) $(LIBFULLNAME)
endif
	-$(DEL) $(FPCMADE) $(PPAS) link.res $(FPCEXTFILE) $(REDIRFILE)

fpc_distclean: fpc_clean

fpc_cleanall: $(CLEANTARGET)
ifdef CLEANEXEFILES
	-$(DEL) $(CLEANEXEFILES)
endif
	-$(DEL) *$(OEXT) *$(PPUEXT) *$(RSTEXT) *$(ASMEXT) *$(STATICLIBEXT) *$(SHAREDLIBEXT) *$(PPLEXT)
	-$(DELTREE) *$(SMARTEXT)
	-$(DEL) $(FPCMADE) $(PPAS) link.res $(FPCEXTFILE) $(REDIRFILE)

#####################################################################
# Info rules
#####################################################################

.PHONY: fpc_info fpc_cfginfo fpc_objectinfo fpc_toolsinfo fpc_installinfo \
	fpc_dirinfo

fpc_info: $(INFOTARGET)

fpc_infocfg:
	@$(ECHO)
	@$(ECHO)  == Configuration info ==
	@$(ECHO)
	@$(ECHO)  FPC....... $(FPC)
	@$(ECHO)  Version... $(FPC_VERSION)
	@$(ECHO)  CPU....... $(CPU_TARGET)
	@$(ECHO)  Source.... $(OS_SOURCE)
	@$(ECHO)  Target.... $(OS_TARGET)
	@$(ECHO)

fpc_infoobjects:
	@$(ECHO)
	@$(ECHO)  == Object info ==
	@$(ECHO)
	@$(ECHO)  LoaderObjects..... $(LOADEROBJECTS)
	@$(ECHO)  UnitObjects....... $(UNITOBJECTS)
	@$(ECHO)  ExeObjects........ $(EXEOBJECTS)
	@$(ECHO)
	@$(ECHO)  ExtraCleanUnits... $(EXTRACLEANUNITS)
	@$(ECHO)  ExtraCleanFiles... $(EXTRACLEANFILES)
	@$(ECHO)
	@$(ECHO)  ExtraInstallUnits. $(EXTRAINSTALLUNITS)
	@$(ECHO)  ExtraInstallFiles. $(EXTRAINSTALLFILES)
	@$(ECHO)

fpc_infoinstall:
	@$(ECHO)
	@$(ECHO)  == Install info ==
	@$(ECHO)
ifdef DATE
	@$(ECHO)  DateStr.............. $(DATESTR)
endif
ifdef PACKAGEPREFIX
	@$(ECHO)  PackagePrefix........ $(PACKAGEPREFIX)
endif
ifdef PACKAGENAME
	@$(ECHO)  PackageName.......... $(PACKAGENAME)
endif
	@$(ECHO)  PackageSuffix........ $(PACKAGESUFFIX)
	@$(ECHO)
	@$(ECHO)  BaseInstallDir....... $(BASEINSTALLDIR)
	@$(ECHO)  BinInstallDir........ $(BININSTALLDIR)
	@$(ECHO)  LibInstallDir........ $(LIBINSTALLDIR)
	@$(ECHO)  UnitInstallDir....... $(UNITINSTALLDIR)
	@$(ECHO)  SourceInstallDir..... $(SOURCEINSTALLDIR)
	@$(ECHO)  DocInstallDir........ $(DOCINSTALLDIR)
	@$(ECHO)  DataInstallDir....... $(DATAINSTALLDIR)
	@$(ECHO)
	@$(ECHO)  DestZipDir........... $(DESTZIPDIR)
	@$(ECHO)  ZipName.............. $(ZIPNAME)
	@$(ECHO)

#####################################################################
# Local Makefile
#####################################################################

ifneq ($(wildcard fpcmake.loc),)
include fpcmake.loc
endif

#####################################################################
# Users rules
#####################################################################

cleartarget:
	-$(DEL) allunits$(EXEEXT)

all: cleartarget allunits$(EXEEXT)
	-$(DEL) allunits$(EXEEXT)
