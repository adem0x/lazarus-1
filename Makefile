#
# Don't edit, this file is generated by FPCMake Version 1.1 [2001/12/31]
#
default: all
override PATH:=$(subst \,/,$(PATH))
ifeq ($(findstring ;,$(PATH)),)
inUnix=1
SEARCHPATH:=$(filter-out .,$(subst :, ,$(PATH)))
else
SEARCHPATH:=$(subst ;, ,$(PATH))
endif
PWD:=$(strip $(wildcard $(addsuffix /pwd.exe,$(SEARCHPATH))))
ifeq ($(PWD),)
PWD:=$(strip $(wildcard $(addsuffix /pwd,$(SEARCHPATH))))
ifeq ($(PWD),)
nopwd:
	@echo You need the GNU utils package to use this Makefile!
	@echo Get ftp://ftp.freepascal.org/pub/fpc/dist/go32v2/utilgo32.zip
	@exit
else
PWD:=$(firstword $(PWD))
SRCEXEEXT=
endif
else
PWD:=$(firstword $(PWD))
SRCEXEEXT=.exe
endif
ifndef inUnix
ifeq ($(OS),Windows_NT)
inWinNT=1
else
ifdef OS2_SHELL
inOS2=1
endif
endif
else
ifneq ($(findstring cygwin,$(MACHTYPE)),)
inCygWin=1
endif
endif
ifeq ($(OS_TARGET),freebsd)
BSDhier=1
endif
ifeq ($(OS_TARGET),netbsd)
BSDhier=1
endif
ifdef inUnix
BATCHEXT=.sh
else
ifdef inOS2
BATCHEXT=.cmd
else
BATCHEXT=.bat
endif
endif
ifdef inUnix
PATHSEP=/
else
PATHSEP:=$(subst /,\,/)
endif
ifdef PWD
BASEDIR:=$(subst \,/,$(shell $(PWD)))
ifdef inCygWin
ifneq ($(findstring /cygdrive/,$(BASEDIR)),)
BASENODIR:=$(patsubst /cygdrive%,%,$(BASEDIR))
BASEDRIVE:=$(firstword $(subst /, ,$(BASENODIR)))
BASEDIR:=$(subst /cygdrive/$(BASEDRIVE)/,$(BASEDRIVE):/,$(BASEDIR))
endif
endif
else
BASEDIR=.
endif
ifndef FPC
ifdef PP
FPC=$(PP)
endif
endif
ifndef FPC
FPCPROG:=$(strip $(wildcard $(addsuffix /fpc$(SRCEXEEXT),$(SEARCHPATH))))
ifneq ($(FPCPROG),)
FPCPROG:=$(firstword $(FPCPROG))
FPC:=$(shell $(FPCPROG) -PB)
ifneq ($(findstring Error,$(FPC)),)
override FPC=ppc386
endif
else
override FPC=ppc386
endif
endif
override FPC:=$(subst $(SRCEXEEXT),,$(FPC))
override FPC:=$(subst \,/,$(FPC))$(SRCEXEEXT)
ifndef FPC_VERSION
FPC_VERSION:=$(shell $(FPC) -iV)
endif
export FPC FPC_VERSION
ifndef CPU_TARGET
CPU_TARGET:=$(shell $(FPC) -iTP)
endif
ifndef CPU_SOURCE
CPU_SOURCE:=$(shell $(FPC) -iSP)
endif
ifndef OS_TARGET
OS_TARGET:=$(shell $(FPC) -iTO)
endif
ifndef OS_SOURCE
OS_SOURCE:=$(shell $(FPC) -iSO)
endif
FULL_TARGET=$(CPU_TARGET)-$(OS_TARGET)
FULL_SOURCE=$(CPU_SOURCE)-$(OS_SOURCE)
ifneq ($(FULL_TARGET),$(FULL_SOURCE))
CROSSCOMPILE=1
endif
export OS_TARGET OS_SOURCE CPU_TARGET CPU_SOURCE FULL_TARGET FULL_SOURCE CROSSCOMPILE
ifdef FPCDIR
override FPCDIR:=$(subst \,/,$(FPCDIR))
ifeq ($(wildcard $(addprefix $(FPCDIR)/,rtl units)),)
override FPCDIR=wrong
endif
else
override FPCDIR=wrong
endif
ifeq ($(FPCDIR),wrong)
ifdef inUnix
override FPCDIR=/usr/local/lib/fpc/$(FPC_VERSION)
ifeq ($(wildcard $(FPCDIR)/units),)
override FPCDIR=/usr/lib/fpc/$(FPC_VERSION)
endif
else
override FPCDIR:=$(subst /$(FPC),,$(firstword $(strip $(wildcard $(addsuffix /$(FPC),$(SEARCHPATH))))))
override FPCDIR:=$(FPCDIR)/..
ifeq ($(wildcard $(addprefix $(FPCDIR)/,rtl units)),)
override FPCDIR:=$(FPCDIR)/..
ifeq ($(wildcard $(addprefix $(FPCDIR)/,rtl units)),)
override FPCDIR=c:/pp
endif
endif
endif
endif
ifndef CROSSDIR
CROSSDIR:=$(FPCDIR)/cross/$(FULL_TARGET)
endif
ifndef CROSSTARGETDIR
CROSSTARGETDIR=$(CROSSDIR)/$(FULL_TARGET)
endif
ifdef CROSSCOMPILE
UNITSDIR:=$(wildcard $(CROSSTARGETDIR)/units)
ifeq ($(UNITSDIR),)
UNITSDIR:=$(wildcard $(FPCDIR)/units/$(OS_TARGET))
endif
else
UNITSDIR:=$(wildcard $(FPCDIR)/units/$(OS_TARGET))
endif
PACKAGESDIR:=$(wildcard $(FPCDIR) $(FPCDIR)/packages)
override PACKAGE_NAME=lazarus
override PACKAGE_VERSION=0.8a
ifndef LCL_PLATFORM
ifeq ($(OS_TARGET), win32)
LCL_PLATFORM=win32
override FPCOPT+=-dSUPPORTS_RESOURCES
export FPCOPT
else
LCL_PLATFORM=gtk
endif
export LCL_PLATFORM
endif
override TARGET_DIRS+=lcl components
override TARGET_PROGRAMS+=lazarus
override TARGET_EXAMPLEDIRS+=examples
override CLEAN_FILES+=$(wildcard ./designer/*$(OEXT)) $(wildcard ./designer/*$(PPUEXT)) $(wildcard ./debugger/*$(OEXT)) $(wildcard ./debugger/*$(PPUEXT))
override INSTALL_BASEDIR=lib/lazarus
override DIST_DESTDIR=$(BASEDIR)/dist
override COMPILER_OPTIONS+=-gl
override COMPILER_INCLUDEDIR+=include include/$(OS_TARGET)
override COMPILER_UNITDIR+=lcl/units lcl/units/$(LCL_PLATFORM) designer debugger components/units .
override COMPILER_TARGETDIR+=.
ifdef REQUIRE_UNITSDIR
override UNITSDIR+=$(REQUIRE_UNITSDIR)
endif
ifdef REQUIRE_PACKAGESDIR
override PACKAGESDIR+=$(REQUIRE_PACKAGESDIR)
endif
ifdef ZIPINSTALL
ifeq ($(OS_TARGET),linux)
UNIXINSTALLDIR=1
endif
ifeq ($(OS_TARGET),freebsd)
UNIXINSTALLDIR=1
endif
ifeq ($(OS_TARGET),netbsd)
UNIXINSTALLDIR=1
endif
ifeq ($(OS_TARGET),sunos)
UNIXINSTALLDIR=1
endif
else
ifeq ($(OS_SOURCE),linux)
UNIXINSTALLDIR=1
endif
ifeq ($(OS_SOURCE),freebsd)
UNIXINSTALLDIR=1
endif
ifeq ($(OS_SOURCE),netbsd)
UNIXINSTALLDIR=1
endif
ifeq ($(OS_TARGET),sunos)
UNIXINSTALLDIR=1
endif
endif
ifndef INSTALL_PREFIX
ifdef UNIXINSTALLDIR
INSTALL_PREFIX=/usr/local
else
ifdef INSTALL_FPCPACKAGE
INSTALL_BASEDIR:=/pp
else
INSTALL_BASEDIR:=/$(PACKAGE_NAME)
endif
endif
endif
export INSTALL_PREFIX
ifndef DIST_DESTDIR
DIST_DESTDIR:=$(BASEDIR)
endif
export DIST_DESTDIR
ifndef INSTALL_BASEDIR
ifdef UNIXINSTALLDIR
ifdef INSTALL_FPCPACKAGE
INSTALL_BASEDIR:=$(INSTALL_PREFIX)/lib/fpc/$(FPC_VERSION)
else
INSTALL_BASEDIR:=$(INSTALL_PREFIX)/lib/$(PACKAGE_NAME)
endif
else
INSTALL_BASEDIR:=$(INSTALL_PREFIX)
endif
endif
ifndef INSTALL_BINDIR
ifdef UNIXINSTALLDIR
INSTALL_BINDIR:=$(INSTALL_PREFIX)/bin
else
INSTALL_BINDIR:=$(INSTALL_BASEDIR)/bin
ifdef INSTALL_FPCPACKAGE
INSTALL_BINDIR:=$(INSTALL_BINDIR)/$(OS_TARGET)
endif
endif
endif
ifndef INSTALL_UNITDIR
ifdef CROSSCOMPILE
INSTALL_UNITDIR:=$(INSTALL_BASEDIR)/cross/$(FULL_TARGET)/units
else
INSTALL_UNITDIR:=$(INSTALL_BASEDIR)/units/$(OS_TARGET)
endif
ifdef INSTALL_FPCPACKAGE
ifdef PACKAGE_NAME
INSTALL_UNITDIR:=$(INSTALL_UNITDIR)/$(PACKAGE_NAME)
endif
endif
endif
ifndef INSTALL_LIBDIR
ifdef UNIXINSTALLDIR
INSTALL_LIBDIR:=$(INSTALL_PREFIX)/lib
else
INSTALL_LIBDIR:=$(INSTALL_UNITDIR)
endif
endif
ifndef INSTALL_SOURCEDIR
ifdef UNIXINSTALLDIR
ifdef INSTALL_FPCPACKAGE
ifdef BSDhier
INSTALL_SOURCEDIR:=$(INSTALL_PREFIX)/share/src/fpc-$(FPC_VERSION)/$(PACKAGE_NAME)
else
INSTALL_SOURCEDIR:=$(INSTALL_PREFIX)/src/fpc-$(FPC_VERSION)/$(PACKAGE_NAME)
endif
else
ifdef BSDhier
INSTALL_SOURCEDIR:=$(INSTALL_PREFIX)/share/src/$(PACKAGE_NAME)-$(PACKAGE_VERSION)
else
INSTALL_SOURCEDIR:=$(INSTALL_PREFIX)/src/$(PACKAGE_NAME)-$(PACKAGE_VERSION)
endif
endif
else
ifdef INSTALL_FPCPACKAGE
INSTALL_SOURCEDIR:=$(INSTALL_BASEDIR)/source/$(PACKAGE_NAME)
else
INSTALL_SOURCEDIRL:=$(INSTALL_BASEDIR)/source
endif
endif
endif
ifndef INSTALL_DOCDIR
ifdef UNIXINSTALLDIR
ifdef INSTALL_FPCPACKAGE
ifdef BSDhier
INSTALL_DOCDIR:=$(INSTALL_PREFIX)/share/doc/fpc-$(FPC_VERSION)/$(PACKAGE_NAME)
else
INSTALL_DOCDIR:=$(INSTALL_PREFIX)/doc/fpc-$(FPC_VERSION)/$(PACKAGE_NAME)
endif
else
ifdef BSDhier
INSTALL_DOCDIR:=$(INSTALL_PREFIX)/share/doc/$(PACKAGE_NAME)-$(PACKAGE_VERSION)
else
INSTALL_DOCDIR:=$(INSTALL_PREFIX)/doc/$(PACKAGE_NAME)-$(PACKAGE_VERSION)
endif
endif
else
ifdef INSTALL_FPCPACKAGE
INSTALL_DOCDIR:=$(INSTALL_BASEDIR)/doc/$(PACKAGE_NAME)
else
INSTALL_DOCDIR:=$(INSTALL_BASEDIR)/doc
endif
endif
endif
ifndef INSTALL_EXAMPLEDIR
ifdef UNIXINSTALLDIR
ifdef INSTALL_FPCPACKAGE
ifdef BSDhier
INSTALL_EXAMPLEDIR:=$(INSTALL_PREFIX)/share/examples/fpc-$(FPC_VERSION)/$(PACKAGE_NAME)
else
INSTALL_EXAMPLEDIR:=$(INSTALL_PREFIX)/doc/fpc-$(FPC_VERSION)/examples/$(PACKAGE_NAME)
endif
else
ifdef BSDhier
INSTALL_EXAMPLEDIR:=$(INSTALL_PREFIX)/share/examples/$(PACKAGE_NAME)-$(PACKAGE_VERSION)
else
INSTALL_EXAMPLEDIR:=$(INSTALL_PREFIX)/doc/$(PACKAGE_NAME)-$(PACKAGE_VERSION)
endif
endif
else
ifdef INSTALL_FPCPACKAGE
INSTALL_EXAMPLEDIR:=$(INSTALL_BASEDIR)/examples/$(PACKAGE_NAME)
else
INSTALL_EXAMPLEDIR:=$(INSTALL_BASEDIR)/examples
endif
endif
endif
ifndef INSTALL_DATADIR
INSTALL_DATADIR=$(INSTALL_BASEDIR)
endif
ifdef CROSSCOMPILE
ifndef CROSSBINDIR
CROSSBINDIR:=$(wildcard $(CROSSTARGETDIR)/bin/$(FULL_SOURCE))
ifeq ($(CROSSBINDIR),)
CROSSBINDIR:=$(wildcard $(INSTALL_BASEDIR)/cross/$(FULL_TARGET)/bin/$(FULL_SOURCE))
endif
endif
else
CROSSBINDIR=
endif
ifdef inUnix
ifndef GCCLIBDIR
GCCLIBDIR:=$(shell dirname `(gcc -v 2>&1)| head -n 1| awk '{ print $$4 } '`)
endif
ifeq ($(OS_TARGET),linux)
ifndef OTHERLIBDIR
OTHERLIBDIR:=$(shell grep -v "^\#" /etc/ld.so.conf | awk '{ ORS=" "; print $1 }')
endif
endif
ifeq ($(OS_TARGET),netbsd)
OTHERLIBDIR+=/usr/pkg/lib
endif
export GCCLIBDIR OTHERLIB
endif
LOADEREXT=.as
EXEEXT=.exe
PPLEXT=.ppl
PPUEXT=.ppu
OEXT=.o
ASMEXT=.s
SMARTEXT=.sl
STATICLIBEXT=.a
SHAREDLIBEXT=.so
STATICLIBPREFIX=libp
RSTEXT=.rst
FPCMADE=fpcmade
ifeq ($(OS_TARGET),go32v1)
PPUEXT=.pp1
OEXT=.o1
ASMEXT=.s1
SMARTEXT=.sl1
STATICLIBEXT=.a1
SHAREDLIBEXT=.so1
STATICLIBPREFIX=
FPCMADE=fpcmade.v1
PACKAGESUFFIX=v1
endif
ifeq ($(OS_TARGET),go32v2)
STATICLIBPREFIX=
FPCMADE=fpcmade.dos
ZIPSUFFIX=go32
endif
ifeq ($(OS_TARGET),linux)
EXEEXT=
HASSHAREDLIB=1
FPCMADE=fpcmade.lnx
ZIPSUFFIX=linux
endif
ifeq ($(OS_TARGET),freebsd)
EXEEXT=
HASSHAREDLIB=1
FPCMADE=fpcmade.freebsd
ZIPSUFFIX=freebsd
endif
ifeq ($(OS_TARGET),netbsd)
EXEEXT=
HASSHAREDLIB=1
FPCMADE=fpcmade.netbsd
ZIPSUFFIX=netbsd
endif
ifeq ($(OS_TARGET),win32)
PPUEXT=.ppw
OEXT=.ow
ASMEXT=.sw
SMARTEXT=.slw
STATICLIBEXT=.aw
SHAREDLIBEXT=.dll
FPCMADE=fpcmade.w32
ZIPSUFFIX=w32
endif
ifeq ($(OS_TARGET),os2)
PPUEXT=.ppo
ASMEXT=.so2
OEXT=.oo2
AOUTEXT=.out
SMARTEXT=.so
STATICLIBEXT=.ao2
SHAREDLIBEXT=.dll
FPCMADE=fpcmade.os2
ZIPSUFFIX=emx
endif
ifeq ($(OS_TARGET),amiga)
EXEEXT=
PPUEXT=.ppa
ASMEXT=.asm
OEXT=.o
SMARTEXT=.sl
STATICLIBEXT=.a
SHAREDLIBEXT=.library
FPCMADE=fpcmade.amg
endif
ifeq ($(OS_TARGET),atari)
PPUEXT=.ppt
ASMEXT=.s
OEXT=.o
SMARTEXT=.sl
STATICLIBEXT=.a
EXEEXT=.ttp
FPCMADE=fpcmade.ata
endif
ifeq ($(OS_TARGET),beos)
PPUEXT=.ppu
ASMEXT=.s
OEXT=.o
SMARTEXT=.sl
STATICLIBEXT=.a
EXEEXT=
FPCMADE=fpcmade.be
ZIPSUFFIX=be
endif
ifeq ($(OS_TARGET),sunos)
PPUEXT=.ppu
ASMEXT=.s
OEXT=.o
SMARTEXT=.sl
STATICLIBEXT=.a
EXEEXT=
FPCMADE=fpcmade.sun
ZIPSUFFIX=sun
endif
ifeq ($(OS_TARGET),qnx)
PPUEXT=.ppu
ASMEXT=.s
OEXT=.o
SMARTEXT=.sl
STATICLIBEXT=.a
EXEEXT=
FPCMADE=fpcmade.qnx
ZIPSUFFIX=qnx
endif
ifndef ECHO
ECHO:=$(strip $(wildcard $(addsuffix /gecho$(SRCEXEEXT),$(SEARCHPATH))))
ifeq ($(ECHO),)
ECHO:=$(strip $(wildcard $(addsuffix /echo$(SRCEXEEXT),$(SEARCHPATH))))
ifeq ($(ECHO),)
ECHO=
else
ECHO:=$(firstword $(ECHO))
endif
else
ECHO:=$(firstword $(ECHO))
endif
endif
export ECHO
ifndef DATE
DATE:=$(strip $(wildcard $(addsuffix /gdate$(SRCEXEEXT),$(SEARCHPATH))))
ifeq ($(DATE),)
DATE:=$(strip $(wildcard $(addsuffix /date$(SRCEXEEXT),$(SEARCHPATH))))
ifeq ($(DATE),)
DATE=
else
DATE:=$(firstword $(DATE))
endif
else
DATE:=$(firstword $(DATE))
endif
endif
export DATE
ifndef GINSTALL
GINSTALL:=$(strip $(wildcard $(addsuffix /ginstall$(SRCEXEEXT),$(SEARCHPATH))))
ifeq ($(GINSTALL),)
GINSTALL:=$(strip $(wildcard $(addsuffix /install$(SRCEXEEXT),$(SEARCHPATH))))
ifeq ($(GINSTALL),)
GINSTALL=
else
GINSTALL:=$(firstword $(GINSTALL))
endif
else
GINSTALL:=$(firstword $(GINSTALL))
endif
endif
export GINSTALL
ifndef CPPROG
CPPROG:=$(strip $(wildcard $(addsuffix /cp$(SRCEXEEXT),$(SEARCHPATH))))
ifeq ($(CPPROG),)
CPPROG=
else
CPPROG:=$(firstword $(CPPROG))
endif
endif
export CPPROG
ifndef RMPROG
RMPROG:=$(strip $(wildcard $(addsuffix /rm$(SRCEXEEXT),$(SEARCHPATH))))
ifeq ($(RMPROG),)
RMPROG=
else
RMPROG:=$(firstword $(RMPROG))
endif
endif
export RMPROG
ifndef MVPROG
MVPROG:=$(strip $(wildcard $(addsuffix /mv$(SRCEXEEXT),$(SEARCHPATH))))
ifeq ($(MVPROG),)
MVPROG=
else
MVPROG:=$(firstword $(MVPROG))
endif
endif
export MVPROG
ifndef ECHOREDIR
ECHOREDIR:=$(subst /,$(PATHSEP),$(ECHO))
endif
ifndef COPY
COPY:=$(CPPROG) -fp
endif
ifndef COPYTREE
COPYTREE:=$(CPPROG) -rfp
endif
ifndef MOVE
MOVE:=$(MVPROG) -f
endif
ifndef DEL
DEL:=$(RMPROG) -f
endif
ifndef DELTREE
DELTREE:=$(RMPROG) -rf
endif
ifndef INSTALL
ifdef inUnix
INSTALL:=$(GINSTALL) -c -m 644
else
INSTALL:=$(COPY)
endif
endif
ifndef INSTALLEXE
ifdef inUnix
INSTALLEXE:=$(GINSTALL) -c -m 755
else
INSTALLEXE:=$(COPY)
endif
endif
ifndef MKDIR
MKDIR:=$(GINSTALL) -m 755 -d
endif
export ECHOREDIR COPY COPYTREE MOVE DEL DELTREE INSTALL INSTALLEXE MKDIR
ifndef PPUMOVE
PPUMOVE:=$(strip $(wildcard $(addsuffix /ppumove$(SRCEXEEXT),$(SEARCHPATH))))
ifeq ($(PPUMOVE),)
PPUMOVE=
else
PPUMOVE:=$(firstword $(PPUMOVE))
endif
endif
export PPUMOVE
ifndef FPCMAKE
FPCMAKE:=$(strip $(wildcard $(addsuffix /fpcmake$(SRCEXEEXT),$(SEARCHPATH))))
ifeq ($(FPCMAKE),)
FPCMAKE=
else
FPCMAKE:=$(firstword $(FPCMAKE))
endif
endif
export FPCMAKE
ifndef ZIPPROG
ZIPPROG:=$(strip $(wildcard $(addsuffix /zip$(SRCEXEEXT),$(SEARCHPATH))))
ifeq ($(ZIPPROG),)
ZIPPROG=
else
ZIPPROG:=$(firstword $(ZIPPROG))
endif
endif
export ZIPPROG
ifndef TARPROG
TARPROG:=$(strip $(wildcard $(addsuffix /tar$(SRCEXEEXT),$(SEARCHPATH))))
ifeq ($(TARPROG),)
TARPROG=
else
TARPROG:=$(firstword $(TARPROG))
endif
endif
export TARPROG
ASNAME=as
LDNAME=ld
ARNAME=ar
RCNAME=rc
ifeq ($(OS_TARGET),win32)
ASNAME=asw
LDNAME=ldw
ARNAME=arw
endif
ifndef ASPROG
ifdef CROSSBINDIR
ASPROG=$(CROSSBINDIR)/$(ASNAME)$(SRCEXEEXT)
else
ASPROG=$(ASNAME)
endif
endif
ifndef LDPROG
ifdef CROSSBINDIR
LDPROG=$(CROSSBINDIR)/$(LDNAME)$(SRCEXEEXT)
else
LDPROG=$(LDNAME)
endif
endif
ifndef RCPROG
ifdef CROSSBINDIR
RCPROG=$(CROSSBINDIR)/$(RCNAME)$(SRCEXEEXT)
else
RCPROG=$(RCNAME)
endif
endif
ifndef ARPROG
ifdef CROSSBINDIR
ARPROG=$(CROSSBINDIR)/$(ARNAME)$(SRCEXEEXT)
else
ARPROG=$(ARNAME)
endif
endif
AS=$(ASPROG)
LD=$(LDPROG)
RC=$(RCPROG)
AR=$(ARPROG)
PPAS=ppas$(BATCHEXT)
ifdef inUnix
LDCONFIG=ldconfig
else
LDCONFIG=
endif
ifdef DATE
DATESTR:=$(shell $(DATE) +%Y%m%d)
else
DATESTR=
endif
ifndef UPXPROG
ifeq ($(OS_TARGET),go32v2)
UPXPROG:=1
endif
ifeq ($(OS_TARGET),win32)
UPXPROG:=1
endif
ifdef UPXPROG
UPXPROG:=$(strip $(wildcard $(addsuffix /upx$(SRCEXEEXT),$(SEARCHPATH))))
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
ZIPOPT=-9
ZIPEXT=.zip
ifeq ($(USETAR),bz2)
TAROPT=vI
TAREXT=.tar.bz2
else
TAROPT=vz
TAREXT=.tar.gz
endif
ifeq ($(OS_TARGET),linux)
REQUIRE_PACKAGES_RTL=1
REQUIRE_PACKAGES_PASZLIB=1
REQUIRE_PACKAGES_INET=1
REQUIRE_PACKAGES_FCL=1
REQUIRE_PACKAGES_REGEXPR=1
REQUIRE_PACKAGES_MYSQL=1
REQUIRE_PACKAGES_IBASE=1
endif
ifeq ($(OS_TARGET),go32v2)
REQUIRE_PACKAGES_RTL=1
REQUIRE_PACKAGES_PASZLIB=1
REQUIRE_PACKAGES_FCL=1
REQUIRE_PACKAGES_REGEXPR=1
endif
ifeq ($(OS_TARGET),win32)
REQUIRE_PACKAGES_RTL=1
REQUIRE_PACKAGES_PASZLIB=1
REQUIRE_PACKAGES_FCL=1
REQUIRE_PACKAGES_REGEXPR=1
REQUIRE_PACKAGES_MYSQL=1
REQUIRE_PACKAGES_IBASE=1
endif
ifeq ($(OS_TARGET),os2)
REQUIRE_PACKAGES_RTL=1
REQUIRE_PACKAGES_PASZLIB=1
REQUIRE_PACKAGES_FCL=1
REQUIRE_PACKAGES_REGEXPR=1
endif
ifeq ($(OS_TARGET),freebsd)
REQUIRE_PACKAGES_RTL=1
REQUIRE_PACKAGES_PASZLIB=1
REQUIRE_PACKAGES_INET=1
REQUIRE_PACKAGES_FCL=1
REQUIRE_PACKAGES_REGEXPR=1
REQUIRE_PACKAGES_MYSQL=1
REQUIRE_PACKAGES_IBASE=1
endif
ifeq ($(OS_TARGET),beos)
REQUIRE_PACKAGES_RTL=1
REQUIRE_PACKAGES_PASZLIB=1
REQUIRE_PACKAGES_FCL=1
REQUIRE_PACKAGES_REGEXPR=1
endif
ifeq ($(OS_TARGET),netbsd)
REQUIRE_PACKAGES_RTL=1
REQUIRE_PACKAGES_PASZLIB=1
REQUIRE_PACKAGES_INET=1
REQUIRE_PACKAGES_FCL=1
REQUIRE_PACKAGES_REGEXPR=1
endif
ifeq ($(OS_TARGET),amiga)
REQUIRE_PACKAGES_RTL=1
REQUIRE_PACKAGES_PASZLIB=1
REQUIRE_PACKAGES_FCL=1
REQUIRE_PACKAGES_REGEXPR=1
endif
ifeq ($(OS_TARGET),atari)
REQUIRE_PACKAGES_RTL=1
REQUIRE_PACKAGES_PASZLIB=1
REQUIRE_PACKAGES_FCL=1
REQUIRE_PACKAGES_REGEXPR=1
endif
ifeq ($(OS_TARGET),sunos)
REQUIRE_PACKAGES_RTL=1
REQUIRE_PACKAGES_PASZLIB=1
REQUIRE_PACKAGES_FCL=1
REQUIRE_PACKAGES_REGEXPR=1
endif
ifeq ($(OS_TARGET),qnx)
REQUIRE_PACKAGES_RTL=1
REQUIRE_PACKAGES_PASZLIB=1
REQUIRE_PACKAGES_FCL=1
REQUIRE_PACKAGES_REGEXPR=1
endif
ifdef REQUIRE_PACKAGES_RTL
PACKAGEDIR_RTL:=$(subst /Makefile.fpc,,$(strip $(wildcard $(addsuffix /rtl/Makefile.fpc,$(PACKAGESDIR)))))
ifneq ($(PACKAGEDIR_RTL),)
PACKAGEDIR_RTL:=$(firstword $(PACKAGEDIR_RTL))
ifeq ($(wildcard $(PACKAGEDIR_RTL)/$(FPCMADE)),)
override COMPILEPACKAGES+=package_rtl
package_rtl:
	$(MAKE) -C $(PACKAGEDIR_RTL) all
endif
ifneq ($(wildcard $(PACKAGEDIR_RTL)/$(OS_TARGET)),)
UNITDIR_RTL=$(PACKAGEDIR_RTL)/$(OS_TARGET)
else
UNITDIR_RTL=$(PACKAGEDIR_RTL)
endif
else
PACKAGEDIR_RTL=
UNITDIR_RTL:=$(subst /Package.fpc,,$(strip $(wildcard $(addsuffix /rtl/Package.fpc,$(UNITSDIR)))))
ifneq ($(UNITDIR_RTL),)
UNITDIR_RTL:=$(firstword $(UNITDIR_RTL))
else
UNITDIR_RTL=
endif
endif
ifdef UNITDIR_RTL
override COMPILER_UNITDIR+=$(UNITDIR_RTL)
endif
endif
ifdef REQUIRE_PACKAGES_PASZLIB
PACKAGEDIR_PASZLIB:=$(subst /Makefile.fpc,,$(strip $(wildcard $(addsuffix /paszlib/Makefile.fpc,$(PACKAGESDIR)))))
ifneq ($(PACKAGEDIR_PASZLIB),)
PACKAGEDIR_PASZLIB:=$(firstword $(PACKAGEDIR_PASZLIB))
ifeq ($(wildcard $(PACKAGEDIR_PASZLIB)/$(FPCMADE)),)
override COMPILEPACKAGES+=package_paszlib
package_paszlib:
	$(MAKE) -C $(PACKAGEDIR_PASZLIB) all
endif
ifneq ($(wildcard $(PACKAGEDIR_PASZLIB)/$(OS_TARGET)),)
UNITDIR_PASZLIB=$(PACKAGEDIR_PASZLIB)/$(OS_TARGET)
else
UNITDIR_PASZLIB=$(PACKAGEDIR_PASZLIB)
endif
else
PACKAGEDIR_PASZLIB=
UNITDIR_PASZLIB:=$(subst /Package.fpc,,$(strip $(wildcard $(addsuffix /paszlib/Package.fpc,$(UNITSDIR)))))
ifneq ($(UNITDIR_PASZLIB),)
UNITDIR_PASZLIB:=$(firstword $(UNITDIR_PASZLIB))
else
UNITDIR_PASZLIB=
endif
endif
ifdef UNITDIR_PASZLIB
override COMPILER_UNITDIR+=$(UNITDIR_PASZLIB)
endif
endif
ifdef REQUIRE_PACKAGES_INET
PACKAGEDIR_INET:=$(subst /Makefile.fpc,,$(strip $(wildcard $(addsuffix /inet/Makefile.fpc,$(PACKAGESDIR)))))
ifneq ($(PACKAGEDIR_INET),)
PACKAGEDIR_INET:=$(firstword $(PACKAGEDIR_INET))
ifeq ($(wildcard $(PACKAGEDIR_INET)/$(FPCMADE)),)
override COMPILEPACKAGES+=package_inet
package_inet:
	$(MAKE) -C $(PACKAGEDIR_INET) all
endif
ifneq ($(wildcard $(PACKAGEDIR_INET)/$(OS_TARGET)),)
UNITDIR_INET=$(PACKAGEDIR_INET)/$(OS_TARGET)
else
UNITDIR_INET=$(PACKAGEDIR_INET)
endif
else
PACKAGEDIR_INET=
UNITDIR_INET:=$(subst /Package.fpc,,$(strip $(wildcard $(addsuffix /inet/Package.fpc,$(UNITSDIR)))))
ifneq ($(UNITDIR_INET),)
UNITDIR_INET:=$(firstword $(UNITDIR_INET))
else
UNITDIR_INET=
endif
endif
ifdef UNITDIR_INET
override COMPILER_UNITDIR+=$(UNITDIR_INET)
endif
endif
ifdef REQUIRE_PACKAGES_FCL
PACKAGEDIR_FCL:=$(subst /Makefile.fpc,,$(strip $(wildcard $(addsuffix /fcl/Makefile.fpc,$(PACKAGESDIR)))))
ifneq ($(PACKAGEDIR_FCL),)
PACKAGEDIR_FCL:=$(firstword $(PACKAGEDIR_FCL))
ifeq ($(wildcard $(PACKAGEDIR_FCL)/$(FPCMADE)),)
override COMPILEPACKAGES+=package_fcl
package_fcl:
	$(MAKE) -C $(PACKAGEDIR_FCL) all
endif
ifneq ($(wildcard $(PACKAGEDIR_FCL)/$(OS_TARGET)),)
UNITDIR_FCL=$(PACKAGEDIR_FCL)/$(OS_TARGET)
else
UNITDIR_FCL=$(PACKAGEDIR_FCL)
endif
else
PACKAGEDIR_FCL=
UNITDIR_FCL:=$(subst /Package.fpc,,$(strip $(wildcard $(addsuffix /fcl/Package.fpc,$(UNITSDIR)))))
ifneq ($(UNITDIR_FCL),)
UNITDIR_FCL:=$(firstword $(UNITDIR_FCL))
else
UNITDIR_FCL=
endif
endif
ifdef UNITDIR_FCL
override COMPILER_UNITDIR+=$(UNITDIR_FCL)
endif
endif
ifdef REQUIRE_PACKAGES_REGEXPR
PACKAGEDIR_REGEXPR:=$(subst /Makefile.fpc,,$(strip $(wildcard $(addsuffix /regexpr/Makefile.fpc,$(PACKAGESDIR)))))
ifneq ($(PACKAGEDIR_REGEXPR),)
PACKAGEDIR_REGEXPR:=$(firstword $(PACKAGEDIR_REGEXPR))
ifeq ($(wildcard $(PACKAGEDIR_REGEXPR)/$(FPCMADE)),)
override COMPILEPACKAGES+=package_regexpr
package_regexpr:
	$(MAKE) -C $(PACKAGEDIR_REGEXPR) all
endif
ifneq ($(wildcard $(PACKAGEDIR_REGEXPR)/$(OS_TARGET)),)
UNITDIR_REGEXPR=$(PACKAGEDIR_REGEXPR)/$(OS_TARGET)
else
UNITDIR_REGEXPR=$(PACKAGEDIR_REGEXPR)
endif
else
PACKAGEDIR_REGEXPR=
UNITDIR_REGEXPR:=$(subst /Package.fpc,,$(strip $(wildcard $(addsuffix /regexpr/Package.fpc,$(UNITSDIR)))))
ifneq ($(UNITDIR_REGEXPR),)
UNITDIR_REGEXPR:=$(firstword $(UNITDIR_REGEXPR))
else
UNITDIR_REGEXPR=
endif
endif
ifdef UNITDIR_REGEXPR
override COMPILER_UNITDIR+=$(UNITDIR_REGEXPR)
endif
endif
ifdef REQUIRE_PACKAGES_MYSQL
PACKAGEDIR_MYSQL:=$(subst /Makefile.fpc,,$(strip $(wildcard $(addsuffix /mysql/Makefile.fpc,$(PACKAGESDIR)))))
ifneq ($(PACKAGEDIR_MYSQL),)
PACKAGEDIR_MYSQL:=$(firstword $(PACKAGEDIR_MYSQL))
ifeq ($(wildcard $(PACKAGEDIR_MYSQL)/$(FPCMADE)),)
override COMPILEPACKAGES+=package_mysql
package_mysql:
	$(MAKE) -C $(PACKAGEDIR_MYSQL) all
endif
ifneq ($(wildcard $(PACKAGEDIR_MYSQL)/$(OS_TARGET)),)
UNITDIR_MYSQL=$(PACKAGEDIR_MYSQL)/$(OS_TARGET)
else
UNITDIR_MYSQL=$(PACKAGEDIR_MYSQL)
endif
else
PACKAGEDIR_MYSQL=
UNITDIR_MYSQL:=$(subst /Package.fpc,,$(strip $(wildcard $(addsuffix /mysql/Package.fpc,$(UNITSDIR)))))
ifneq ($(UNITDIR_MYSQL),)
UNITDIR_MYSQL:=$(firstword $(UNITDIR_MYSQL))
else
UNITDIR_MYSQL=
endif
endif
ifdef UNITDIR_MYSQL
override COMPILER_UNITDIR+=$(UNITDIR_MYSQL)
endif
endif
ifdef REQUIRE_PACKAGES_IBASE
PACKAGEDIR_IBASE:=$(subst /Makefile.fpc,,$(strip $(wildcard $(addsuffix /ibase/Makefile.fpc,$(PACKAGESDIR)))))
ifneq ($(PACKAGEDIR_IBASE),)
PACKAGEDIR_IBASE:=$(firstword $(PACKAGEDIR_IBASE))
ifeq ($(wildcard $(PACKAGEDIR_IBASE)/$(FPCMADE)),)
override COMPILEPACKAGES+=package_ibase
package_ibase:
	$(MAKE) -C $(PACKAGEDIR_IBASE) all
endif
ifneq ($(wildcard $(PACKAGEDIR_IBASE)/$(OS_TARGET)),)
UNITDIR_IBASE=$(PACKAGEDIR_IBASE)/$(OS_TARGET)
else
UNITDIR_IBASE=$(PACKAGEDIR_IBASE)
endif
else
PACKAGEDIR_IBASE=
UNITDIR_IBASE:=$(subst /Package.fpc,,$(strip $(wildcard $(addsuffix /ibase/Package.fpc,$(UNITSDIR)))))
ifneq ($(UNITDIR_IBASE),)
UNITDIR_IBASE:=$(firstword $(UNITDIR_IBASE))
else
UNITDIR_IBASE=
endif
endif
ifdef UNITDIR_IBASE
override COMPILER_UNITDIR+=$(UNITDIR_IBASE)
endif
endif
.PHONY: package_rtl package_paszlib package_inet package_fcl package_regexpr package_mysql package_ibase
ifndef NOCPUDEF
override FPCOPTDEF=$(CPU_TARGET)
endif
ifneq ($(OS_TARGET),$(OS_SOURCE))
override FPCOPT+=-T$(OS_TARGET)
endif
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
ifdef LINKSMART
override FPCOPT+=-XX
endif
ifdef CREATESMART
override FPCOPT+=-CX
endif
ifdef DEBUG
override FPCOPT+=-gl
override FPCOPTDEF+=DEBUG
endif
ifdef RELEASE
ifeq ($(CPU_TARGET),i386)
FPCCPUOPT:=-OG2p3
else
FPCCPUOPT:=
endif
override FPCOPT+=-Xs $(FPCCPUOPT) -n
override FPCOPTDEF+=RELEASE
endif
ifdef STRIP
override FPCOPT+=-Xs
endif
ifdef OPTIMIZE
ifeq ($(CPU_TARGET),i386)
override FPCOPT+=-OG2p3
endif
endif
ifdef VERBOSE
override FPCOPT+=-vwni
endif
ifdef COMPILER_OPTIONS
override FPCOPT+=$(COMPILER_OPTIONS)
endif
ifdef COMPILER_UNITDIR
override FPCOPT+=$(addprefix -Fu,$(COMPILER_UNITDIR))
endif
ifdef COMPILER_LIBRARYDIR
override FPCOPT+=$(addprefix -Fl,$(COMPILER_LIBRARYDIR))
endif
ifdef COMPILER_OBJECTDIR
override FPCOPT+=$(addprefix -Fo,$(COMPILER_OBJECTDIR))
endif
ifdef COMPILER_INCLUDEDIR
override FPCOPT+=$(addprefix -Fi,$(COMPILER_INCLUDEDIR))
endif
ifdef CROSSBINDIR
override FPCOPT+=-FD$(CROSSBINDIR)
endif
ifdef COMPILER_TARGETDIR
override FPCOPT+=-FE$(COMPILER_TARGETDIR)
ifeq ($(COMPILER_TARGETDIR),.)
override TARGETDIRPREFIX=
else
override TARGETDIRPREFIX=$(COMPILER_TARGETDIR)/
endif
endif
ifdef COMPILER_UNITTARGETDIR
override FPCOPT+=-FU$(COMPILER_UNITTARGETDIR)
ifeq ($(COMPILER_UNITTARGETDIR),.)
override UNITTARGETDIRPREFIX=
else
override UNITTARGETDIRPREFIX=$(COMPILER_UNITTARGETDIR)/
endif
else
ifdef COMPILER_TARGETDIR
override COMPILER_UNITTARGETDIR=$(COMPILER_TARGETDIR)
override UNITTARGETDIRPREFIX=$(TARGETDIRPREFIX)
endif
endif
ifdef GCCLIBDIR
override FPCOPT+=-Fl$(GCCLIBDIR)
endif
ifdef OTHERLIBDIR
override FPCOPT+=$(addprefix -Fl,$(OTHERLIBDIR))
endif
ifdef OPT
override FPCOPT+=$(OPT)
endif
ifdef FPCOPTDEF
override FPCOPT+=$(addprefix -d,$(FPCOPTDEF))
endif
ifdef CFGFILE
override FPCOPT+=@$(CFGFILE)
endif
ifdef USEENV
override FPCEXTCMD:=$(FPCOPT)
override FPCOPT:=!FPCEXTCMD
export FPCEXTCMD
endif
override COMPILER:=$(FPC) $(FPCOPT)
ifeq (,$(findstring -s ,$(COMPILER)))
EXECPPAS=
else
ifeq ($(OS_SOURCE),$(OS_TARGET))
EXECPPAS:=@$(PPAS)
endif
endif
.PHONY: fpc_exes
ifdef TARGET_PROGRAMS
override EXEFILES=$(addsuffix $(EXEEXT),$(TARGET_PROGRAMS))
override EXEOFILES:=$(addsuffix $(OEXT),$(TARGET_PROGRAMS)) $(addprefix $(STATICLIBPREFIX),$(addsuffix $(STATICLIBEXT),$(TARGET_PROGRAMS)))
override ALLTARGET+=fpc_exes
override INSTALLEXEFILES+=$(EXEFILES)
override CLEANEXEFILES+=$(EXEFILES) $(EXEOFILES)
ifeq ($(OS_TARGET),os2)
override CLEANEXEFILES+=$(addsuffix $(AOUTEXT),$(TARGET_PROGRAMS))
endif
endif
fpc_exes: $(EXEFILES)
ifdef TARGET_RSTS
override RSTFILES=$(addsuffix $(RSTEXT),$(TARGET_RSTS))
override CLEANRSTFILES+=$(RSTFILES)
endif
.PHONY: fpc_examples
ifdef TARGET_EXAMPLES
HASEXAMPLES=1
override EXAMPLESOURCEFILES:=$(wildcard $(addsuffix .pp,$(TARGET_EXAMPLES)) $(addsuffix .pas,$(TARGET_EXAMPLES)))
override EXAMPLEFILES:=$(addsuffix $(EXEEXT),$(TARGET_EXAMPLES))
override EXAMPLEOFILES:=$(addsuffix $(OEXT),$(TARGET_EXAMPLES)) $(addprefix $(STATICLIBPREFIX),$(addsuffix $(STATICLIBEXT),$(TARGET_EXAMPLES)))
override CLEANEXEFILES+=$(EXAMPLEFILES) $(EXAMPLEOFILES)
ifeq ($(OS_TARGET),os2)
override CLEANEXEFILES+=$(addsuffix $(AOUTEXT),$(TARGET_EXAMPLES))
endif
endif
ifdef TARGET_EXAMPLEDIRS
HASEXAMPLES=1
endif
fpc_examples: all $(EXAMPLEFILES) $(addsuffix _all,$(TARGET_EXAMPLEDIRS))
.PHONY: fpc_packages fpc_all fpc_smart fpc_debug
$(FPCMADE): $(ALLTARGET)
	@$(ECHOREDIR) Compiled > $(FPCMADE)
fpc_packages: $(COMPILEPACKAGES)
fpc_all: fpc_packages $(FPCMADE)
fpc_smart:
	$(MAKE) all LINKSMART=1 CREATESMART=1
fpc_debug:
	$(MAKE) all DEBUG=1
.SUFFIXES: $(EXEEXT) $(PPUEXT) $(OEXT) .pas .pp
%$(PPUEXT): %.pp
	$(COMPILER) $<
	$(EXECPPAS)
%$(PPUEXT): %.pas
	$(COMPILER) $<
	$(EXECPPAS)
%$(EXEEXT): %.pp
	$(COMPILER) $<
	$(EXECPPAS)
%$(EXEEXT): %.pas
	$(COMPILER) $<
	$(EXECPPAS)
vpath %.pp $(COMPILER_SOURCEDIR) $(COMPILER_INCLUDEDIR)
vpath %.pas $(COMPILER_SOURCEDIR) $(COMPILER_INCLUDEDIR)
vpath %$(PPUEXT) $(COMPILER_UNITTARGETDIR)
.PHONY: fpc_install fpc_sourceinstall fpc_exampleinstall
ifdef INSTALL_UNITS
override INSTALLPPUFILES+=$(addsuffix $(PPUEXT),$(INSTALL_UNITS))
endif
ifdef INSTALLPPUFILES
override INSTALLPPULINKFILES:=$(subst $(PPUEXT),$(OEXT),$(INSTALLPPUFILES)) $(addprefix $(STATICLIBPREFIX),$(subst $(PPUEXT),$(STATICLIBEXT),$(INSTALLPPUFILES)))
override INSTALLPPUFILES:=$(addprefix $(UNITTARGETDIRPREFIX),$(INSTALLPPUFILES))
override INSTALLPPULINKFILES:=$(wildcard $(addprefix $(UNITTARGETDIRPREFIX),$(INSTALLPPULINKFILES)))
override INSTALL_CREATEPACKAGEFPC=1
endif
ifdef INSTALLEXEFILES
override INSTALLEXEFILES:=$(addprefix $(TARGETDIRPREFIX),$(INSTALLEXEFILES))
endif
fpc_install: all $(INSTALLTARGET)
ifdef INSTALLEXEFILES
	$(MKDIR) $(INSTALL_BINDIR)
ifdef UPXPROG
	-$(UPXPROG) $(INSTALLEXEFILES)
endif
	$(INSTALLEXE) $(INSTALLEXEFILES) $(INSTALL_BINDIR)
endif
ifdef INSTALL_CREATEPACKAGEFPC
ifdef FPCMAKE
ifdef PACKAGE_VERSION
ifneq ($(wildcard Makefile.fpc),)
	$(FPCMAKE) -p -T$(OS_TARGET) Makefile.fpc
	$(MKDIR) $(INSTALL_UNITDIR)
	$(INSTALL) Package.fpc $(INSTALL_UNITDIR)
endif
endif
endif
endif
ifdef INSTALLPPUFILES
	$(MKDIR) $(INSTALL_UNITDIR)
	$(INSTALL) $(INSTALLPPUFILES) $(INSTALL_UNITDIR)
ifneq ($(INSTALLPPULINKFILES),)
	$(INSTALL) $(INSTALLPPULINKFILES) $(INSTALL_UNITDIR)
endif
ifneq ($(wildcard $(LIB_FULLNAME)),)
	$(MKDIR) $(INSTALL_LIBDIR)
	$(INSTALL) $(LIB_FULLNAME) $(INSTALL_LIBDIR)
ifdef inUnix
	ln -sf $(LIB_FULLNAME) $(INSTALL_LIBDIR)/$(LIB_NAME)
endif
endif
endif
ifdef INSTALL_FILES
	$(MKDIR) $(INSTALL_DATADIR)
	$(INSTALL) $(INSTALL_FILES) $(INSTALL_DATADIR)
endif
fpc_sourceinstall: distclean
	$(MKDIR) $(INSTALL_SOURCEDIR)
	$(COPYTREE) $(BASEDIR) $(INSTALL_SOURCEDIR)
fpc_exampleinstall: $(addsuffix _distclean,$(TARGET_EXAMPLEDIRS))
ifdef HASEXAMPLES
	$(MKDIR) $(INSTALL_EXAMPLEDIR)
endif
ifdef EXAMPLESOURCEFILES
	$(COPY) $(EXAMPLESOURCEFILES) $(INSTALL_EXAMPLEDIR)
endif
ifdef TARGET_EXAMPLEDIRS
	$(COPYTREE) $(addsuffix /*,$(TARGET_EXAMPLEDIRS)) $(INSTALL_EXAMPLEDIR)
endif
.PHONY: fpc_distinstall
fpc_distinstall: install exampleinstall
.PHONY: fpc_zipinstall fpc_zipsourceinstall fpc_zipexampleinstall
ifndef PACKDIR
ifndef inUnix
PACKDIR=$(BASEDIR)/../fpc-pack
else
PACKDIR=/tmp/fpc-pack
endif
endif
ifndef ZIPNAME
ifdef DIST_ZIPNAME
ZIPNAME=$(DIST_ZIPNAME)
else
ZIPNAME=$(ZIPPREFIX)$(PACKAGE_NAME)$(ZIPSUFFIX)
endif
endif
ifndef ZIPTARGET
ifdef DIST_ZIPTARGET
ZIPTARGET=DIST_ZIPTARGET
else
ZIPTARGET=install
endif
endif
ifndef USEZIP
ifdef inUnix
USETAR=1
endif
endif
ifndef inUnix
USEZIPWRAPPER=1
endif
ifdef USEZIPWRAPPER
ZIPPATHSEP=$(PATHSEP)
ZIPWRAPPER=$(subst /,$(PATHSEP),$(DIST_DESTDIR)/fpczip$(BATCHEXT))
else
ZIPPATHSEP=/
endif
ZIPCMD_CDPACK:=cd $(subst /,$(ZIPPATHSEP),$(PACKDIR))
ZIPCMD_CDBASE:=cd $(subst /,$(ZIPPATHSEP),$(BASEDIR))
ifdef USETAR
ZIPDESTFILE:=$(DIST_DESTDIR)/$(ZIPNAME)$(TAREXT)
ZIPCMD_ZIP:=$(TARPROG) cf$(TAROPT) $(ZIPDESTFILE) *
else
ZIPDESTFILE:=$(DIST_DESTDIR)/$(ZIPNAME)$(ZIPEXT)
ZIPCMD_ZIP:=$(subst /,$(ZIPPATHSEP),$(ZIPPROG)) -Dr $(ZIPOPT) $(ZIPDESTFILE) *
endif
fpc_zipinstall:
	$(MAKE) $(ZIPTARGET) INSTALL_PREFIX=$(PACKDIR) ZIPINSTALL=1
	$(MKDIR) $(DIST_DESTDIR)
	$(DEL) $(ZIPDESTFILE)
ifdef USEZIPWRAPPER
ifneq ($(ECHOREDIR),echo)
	$(ECHOREDIR) -e "$(subst \,\\,$(ZIPCMD_CDPACK))" > $(ZIPWRAPPER)
	$(ECHOREDIR) -e "$(subst \,\\,$(ZIPCMD_ZIP))" >> $(ZIPWRAPPER)
	$(ECHOREDIR) -e "$(subst \,\\,$(ZIPCMD_CDBASE))" >> $(ZIPWRAPPER)
else
	echo $(ZIPCMD_CDPACK) > $(ZIPWRAPPER)
	echo $(ZIPCMD_ZIP) >> $(ZIPWRAPPER)
	echo $(ZIPCMD_CDBASE) >> $(ZIPWRAPPER)
endif
ifdef inUnix
	/bin/sh $(ZIPWRAPPER)
else
	$(ZIPWRAPPER)
endif
	$(DEL) $(ZIPWRAPPER)
else
	$(ZIPCMD_CDPACK) ; $(ZIPCMD_ZIP) ; $(ZIPCMD_CDBASE)
endif
	$(DELTREE) $(PACKDIR)
fpc_zipsourceinstall:
	$(MAKE) fpc_zipinstall ZIPTARGET=sourceinstall ZIPSUFFIX=src
fpc_zipexampleinstall:
ifdef HASEXAMPLES
	$(MAKE) fpc_zipinstall ZIPTARGET=exampleinstall ZIPSUFFIX=exm
endif
fpc_zipdistinstall:
	$(MAKE) fpc_zipinstall ZIPTARGET=distinstall
.PHONY: fpc_clean fpc_cleanall fpc_distclean
ifdef EXEFILES
override CLEANEXEFILES:=$(addprefix $(TARGETDIRPREFIX),$(CLEANEXEFILES))
endif
ifdef CLEAN_UNITS
override CLEANPPUFILES+=$(addsuffix $(PPUEXT),$(CLEAN_UNITS))
endif
ifdef CLEANPPUFILES
override CLEANPPULINKFILES:=$(subst $(PPUEXT),$(OEXT),$(CLEANPPUFILES)) $(addprefix $(STATICLIBPREFIX),$(subst $(PPUEXT),$(STATICLIBEXT),$(CLEANPPUFILES)))
override CLEANPPUFILES:=$(addprefix $(UNITTARGETDIRPREFIX),$(CLEANPPUFILES))
override CLEANPPULINKFILES:=$(wildcard $(addprefix $(UNITTARGETDIRPREFIX),$(CLEANPPULINKFILES)))
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
	-$(DEL) $(addprefix $(UNITTARGETDIRPREFIX),$(CLEANRSTFILES))
endif
ifdef CLEAN_FILES
	-$(DEL) $(CLEAN_FILES)
endif
ifdef LIB_NAME
	-$(DEL) $(LIB_NAME) $(LIB_FULLNAME)
endif
	-$(DEL) $(FPCMADE) Package.fpc $(PPAS) script.res link.res $(FPCEXTFILE) $(REDIRFILE)
fpc_distclean: clean
ifdef COMPILER_UNITTARGETDIR
TARGETDIRCLEAN=fpc_clean
endif
fpc_cleanall: $(CLEANTARGET) $(TARGETDIRCLEAN)
ifdef CLEANEXEFILES
	-$(DEL) $(CLEANEXEFILES)
endif
	-$(DEL) *$(OEXT) *$(PPUEXT) *$(RSTEXT) *$(ASMEXT) *$(STATICLIBEXT) *$(SHAREDLIBEXT) *$(PPLEXT)
	-$(DELTREE) *$(SMARTEXT)
	-$(DEL) $(FPCMADE) $(PPAS) link.res $(FPCEXTFILE) $(REDIRFILE)
ifdef AOUTEXT
	-$(DEL) *$(AOUTEXT)
endif
.PHONY: fpc_info
fpc_info:
	@$(ECHO)
	@$(ECHO)  == Package info ==
	@$(ECHO)  Package Name..... $(PACKAGE_NAME)
	@$(ECHO)  Package Version.. $(PACKAGE_VERSION)
	@$(ECHO)
	@$(ECHO)  == Configuration info ==
	@$(ECHO)
	@$(ECHO)  FPC.......... $(FPC)
	@$(ECHO)  FPC Version.. $(FPC_VERSION)
	@$(ECHO)  Source CPU... $(CPU_SOURCE)
	@$(ECHO)  Target CPU... $(CPU_TARGET)
	@$(ECHO)  Source OS.... $(OS_SOURCE)
	@$(ECHO)  Target OS.... $(OS_TARGET)
	@$(ECHO)  Full Target.. $(FULL_SOURCE)
	@$(ECHO)  Full Source.. $(FULL_TARGET)
	@$(ECHO)
	@$(ECHO)  == Directory info ==
	@$(ECHO)
	@$(ECHO)  Basedir......... $(BASEDIR)
	@$(ECHO)  FPCDir.......... $(FPCDIR)
	@$(ECHO)  CrossBinDir..... $(CROSSBINDIR)
	@$(ECHO)  UnitsDir........ $(UNITSDIR)
	@$(ECHO)  PackagesDir..... $(PACKAGESDIR)
	@$(ECHO)
	@$(ECHO)  GCC library..... $(GCCLIBDIR)
	@$(ECHO)  Other library... $(OTHERLIBDIR)
	@$(ECHO)
	@$(ECHO)  == Tools info ==
	@$(ECHO)
	@$(ECHO)  As........ $(AS)
	@$(ECHO)  Ld........ $(LD)
	@$(ECHO)  Ar........ $(AR)
	@$(ECHO)  Rc........ $(RC)
	@$(ECHO)
	@$(ECHO)  Mv........ $(MVPROG)
	@$(ECHO)  Cp........ $(CPPROG)
	@$(ECHO)  Rm........ $(RMPROG)
	@$(ECHO)  GInstall.. $(GINSTALL)
	@$(ECHO)  Echo...... $(ECHO)
	@$(ECHO)  Date...... $(DATE)
	@$(ECHO)  FPCMake... $(FPCMAKE)
	@$(ECHO)  PPUMove... $(PPUMOVE)
	@$(ECHO)  Upx....... $(UPXPROG)
	@$(ECHO)  Zip....... $(ZIPPROG)
	@$(ECHO)
	@$(ECHO)  == Object info ==
	@$(ECHO)
	@$(ECHO)  Target Loaders...... $(TARGET_LOADERS)
	@$(ECHO)  Target Units........ $(TARGET_UNITS)
	@$(ECHO)  Target Programs..... $(TARGET_PROGRAMS)
	@$(ECHO)  Target Dirs......... $(TARGET_DIRS)
	@$(ECHO)  Target Examples..... $(TARGET_EXAMPLES)
	@$(ECHO)  Target ExampleDirs.. $(TARGET_EXAMPLEDIRS)
	@$(ECHO)
	@$(ECHO)  Clean Units......... $(CLEAN_UNITS)
	@$(ECHO)  Clean Files......... $(CLEAN_FILES)
	@$(ECHO)
	@$(ECHO)  Install Units....... $(INSTALL_UNITS)
	@$(ECHO)  Install Files....... $(INSTALL_FILES)
	@$(ECHO)
	@$(ECHO)  == Install info ==
	@$(ECHO)
	@$(ECHO)  DateStr.............. $(DATESTR)
	@$(ECHO)  ZipPrefix............ $(ZIPPREFIX)
	@$(ECHO)  ZipSuffix............ $(ZIPSUFFIX)
	@$(ECHO)  Install FPC Package.. $(INSTALL_FPCPACKAGE)
	@$(ECHO)
	@$(ECHO)  Install base dir..... $(INSTALL_BASEDIR)
	@$(ECHO)  Install binary dir... $(INSTALL_BINDIR)
	@$(ECHO)  Install library dir.. $(INSTALL_LIBDIR)
	@$(ECHO)  Install units dir.... $(INSTALL_UNITDIR)
	@$(ECHO)  Install source dir... $(INSTALL_SOURCEDIR)
	@$(ECHO)  Install doc dir...... $(INSTALL_DOCDIR)
	@$(ECHO)  Install example dir.. $(INSTALL_EXAMPLEDIR)
	@$(ECHO)  Install data dir..... $(INSTALL_DATADIR)
	@$(ECHO)
	@$(ECHO)  Dist destination dir. $(DIST_DESTDIR)
	@$(ECHO)  Dist zip name........ $(DIST_ZIPNAME)
	@$(ECHO)
TARGET_DIRS_LCL=1
TARGET_DIRS_COMPONENTS=1
ifdef TARGET_DIRS_LCL
lcl_all:
	$(MAKE) -C lcl all
lcl_debug:
	$(MAKE) -C lcl debug
lcl_smart:
	$(MAKE) -C lcl smart
lcl_examples:
	$(MAKE) -C lcl examples
lcl_shared:
	$(MAKE) -C lcl shared
lcl_install:
	$(MAKE) -C lcl install
lcl_sourceinstall:
	$(MAKE) -C lcl sourceinstall
lcl_exampleinstall:
	$(MAKE) -C lcl exampleinstall
lcl_distinstall:
	$(MAKE) -C lcl distinstall
lcl_zipinstall:
	$(MAKE) -C lcl zipinstall
lcl_zipsourceinstall:
	$(MAKE) -C lcl zipsourceinstall
lcl_zipexampleinstall:
	$(MAKE) -C lcl zipexampleinstall
lcl_zipdistinstall:
	$(MAKE) -C lcl zipdistinstall
lcl_clean:
	$(MAKE) -C lcl clean
lcl_distclean:
	$(MAKE) -C lcl distclean
lcl_cleanall:
	$(MAKE) -C lcl cleanall
lcl_info:
	$(MAKE) -C lcl info
lcl:
	$(MAKE) -C lcl all
.PHONY: lcl_all lcl_debug lcl_smart lcl_examples lcl_shared lcl_install lcl_sourceinstall lcl_exampleinstall lcl_distinstall lcl_zipinstall lcl_zipsourceinstall lcl_zipexampleinstall lcl_zipdistinstall lcl_clean lcl_distclean lcl_cleanall lcl_info lcl
endif
ifdef TARGET_DIRS_COMPONENTS
components_all:
	$(MAKE) -C components all
components_debug:
	$(MAKE) -C components debug
components_smart:
	$(MAKE) -C components smart
components_examples:
	$(MAKE) -C components examples
components_shared:
	$(MAKE) -C components shared
components_install:
	$(MAKE) -C components install
components_sourceinstall:
	$(MAKE) -C components sourceinstall
components_exampleinstall:
	$(MAKE) -C components exampleinstall
components_distinstall:
	$(MAKE) -C components distinstall
components_zipinstall:
	$(MAKE) -C components zipinstall
components_zipsourceinstall:
	$(MAKE) -C components zipsourceinstall
components_zipexampleinstall:
	$(MAKE) -C components zipexampleinstall
components_zipdistinstall:
	$(MAKE) -C components zipdistinstall
components_clean:
	$(MAKE) -C components clean
components_distclean:
	$(MAKE) -C components distclean
components_cleanall:
	$(MAKE) -C components cleanall
components_info:
	$(MAKE) -C components info
components:
	$(MAKE) -C components all
.PHONY: components_all components_debug components_smart components_examples components_shared components_install components_sourceinstall components_exampleinstall components_distinstall components_zipinstall components_zipsourceinstall components_zipexampleinstall components_zipdistinstall components_clean components_distclean components_cleanall components_info components
endif
TARGET_EXAMPLEDIRS_EXAMPLES=1
ifdef TARGET_EXAMPLEDIRS_EXAMPLES
examples_all:
	$(MAKE) -C examples all
examples_debug:
	$(MAKE) -C examples debug
examples_smart:
	$(MAKE) -C examples smart
examples_examples:
	$(MAKE) -C examples examples
examples_shared:
	$(MAKE) -C examples shared
examples_install:
	$(MAKE) -C examples install
examples_sourceinstall:
	$(MAKE) -C examples sourceinstall
examples_exampleinstall:
	$(MAKE) -C examples exampleinstall
examples_distinstall:
	$(MAKE) -C examples distinstall
examples_zipinstall:
	$(MAKE) -C examples zipinstall
examples_zipsourceinstall:
	$(MAKE) -C examples zipsourceinstall
examples_zipexampleinstall:
	$(MAKE) -C examples zipexampleinstall
examples_zipdistinstall:
	$(MAKE) -C examples zipdistinstall
examples_clean:
	$(MAKE) -C examples clean
examples_distclean:
	$(MAKE) -C examples distclean
examples_cleanall:
	$(MAKE) -C examples cleanall
examples_info:
	$(MAKE) -C examples info
examples:
	$(MAKE) -C examples all
.PHONY: examples_all examples_debug examples_smart examples_examples examples_shared examples_install examples_sourceinstall examples_exampleinstall examples_distinstall examples_zipinstall examples_zipsourceinstall examples_zipexampleinstall examples_zipdistinstall examples_clean examples_distclean examples_cleanall examples_info examples
endif
debug: fpc_debug
smart: fpc_smart
examples: fpc_examples $(addsuffix _examples,$(TARGET_DIRS))
shared: $(addsuffix _shared,$(TARGET_DIRS))
install: fpc_install $(addsuffix _install,$(TARGET_DIRS))
sourceinstall: fpc_sourceinstall
exampleinstall: fpc_exampleinstall $(addsuffix _exampleinstall,$(TARGET_DIRS))
distinstall: fpc_distinstall
zipinstall: fpc_zipinstall
zipsourceinstall: fpc_zipsourceinstall
zipexampleinstall: fpc_zipexampleinstall $(addsuffix _zipexampleinstall,$(TARGET_DIRS))
zipdistinstall: fpc_zipdistinstall $(addsuffix _zipdistinstall,$(TARGET_DIRS))
distclean: fpc_distclean $(addsuffix _distclean,$(TARGET_DIRS))
cleanall: fpc_cleanall $(addsuffix _cleanall,$(TARGET_DIRS))
info: fpc_info
.PHONY: debug smart examples shared install sourceinstall exampleinstall distinstall zipinstall zipsourceinstall zipexampleinstall zipdistinstall distclean cleanall info
ifneq ($(wildcard fpcmake.loc),)
include fpcmake.loc
endif
.PHONY: examples lcl components ide tools all clean
ide:
ifeq ($(LCL_PLATFORM), win32)
	$(MAKE) lazarus.res
endif
	$(MAKE) --assume-new=lazarus.pp lazarus$(EXEEXT)
tools: lcl components tools_all
all: lcl components ide
clean: cleanall
	$(DEL) $(wildcard ./designer/*$(OEXT))
	$(wildcard ./designer/*$(PPUEXT))
	$(wildcard ./debugger/*$(OEXT))
	$(wildcard ./debugger/*$(PPUEXT))
ifeq ($(LCL_PLATFORM), win32)
	$(DEL) $(wildcard *.res)
	$(DEL) lazarus.owr
endif
