# Make command to use for dependencies
SHELL=/bin/sh
RM:=rm
MKDIR:=mkdir
OS:=$(shell uname)
EXE_POSTFIX:=""


# ---------------------------------------------------------------- #
# Figure out if we're building in the Steam tree or not.
# ---------------------------------------------------------------- #

SRCROOT:=src
-include $(SRCROOT)/devtools/steam_def.mak


# ---------------------------------------------------------------- #
# Set paths to gcc.
# ---------------------------------------------------------------- #

CC:=gcc
CXX:=g++

ifeq ($(OS),Darwin)
	SDKROOT:=$(shell xcodebuild -sdk macosx -version Path)
	CC:=clang -m32
	CXX:=clang++ -m32
	EXE_POSTFIX:=_osx
endif

ifeq ($(OS),Linux)
ifeq ($(wildcard /valve/bin/gcc),)
	CC:=gcc
	CXX:=g++
else
	CC:=/valve/bin/gcc-4.7
	CXX:=/valve/bin/g++-4.7
endif
	EXE_POSTFIX:=_linux
endif

ifneq ($(CC_OVERRIDE),)
		CC:=$(CC_OVERRIDE)
		CXX:=$(CPP_OVERRIDE)
endif


# ---------------------------------------------------------------- #
# Lists of files.
# ---------------------------------------------------------------- #

VPC_SRC:= \
	src/exprsimplifier.cpp \
	src/groupscript.cpp \
	src/conditionals.cpp \
	src/macros.cpp \
	src/projectscript.cpp \
	src/scriptsource.cpp \
	src/baseprojectdatacollector.cpp \
	src/configuration.cpp \
	src/dependencies.cpp \
	src/main.cpp \
	src/projectgenerator_makefile.cpp \
	src/solutiongenerator_makefile.cpp \
	src/solutiongenerator_xcode.cpp \
	src/sys_utils.cpp \
	src/crccheck_shared.cpp \
	src/projectgenerator_codelite.cpp \
	src/solutiongenerator_codelite.cpp \

TIER0_SRC:= \
	src/tier0/assert_dialog.cpp \
	src/tier0/cpu_posix.cpp \
	src/tier0/cpu.cpp \
	src/tier0/dbg.cpp \
	src/tier0/fasttimer.cpp \
	src/tier0/mem.cpp \
	src/tier0/mem_helpers.cpp \
	src/tier0/memdbg.cpp \
	src/tier0/memstd.cpp \
	src/tier0/memvalidate.cpp \
	src/tier0/minidump.cpp \
	src/tier0/pch_tier0.cpp \
	src/tier0/threadtools.cpp \
	src/tier0/valobject.cpp \
	src/tier0/vprof.cpp 


TIER1_SRC:= \
	src/tier1/keyvalues.cpp \
	src/tier1/checksum_crc.cpp \
	src/tier1/checksum_md5.cpp \
	src/tier1/convar.cpp \
	src/tier1/generichash.cpp \
	src/tier1/interface.cpp \
	src/tier1/mempool.cpp \
	src/tier1/memstack.cpp \
	src/tier1/stringpool.cpp \
	src/tier1/utlbuffer.cpp \
	src/tier1/utlsymbol.cpp 

VSTDLIB_SRC:= \
	src/vstdlib/cvar.cpp \
	src/vstdlib/vstrtools.cpp \
	src/vstdlib/random.cpp


ifeq "$(STEAM_BRANCH)" "1"
	TIER0_SRC+= \
		src/tier0/tier0.cpp \
		src/tier0/platform_posix.cpp \
		src/tier0/validator.cpp \
		src/tier0/thread.cpp \
		src/tier0/pmelib.cpp \
		src/tier0/pme_posix.cpp \
		src/tier0/testthread.cpp \
		src/tier0/cpu_posix.cpp \
		src/tier0/memblockhdr.cpp 

	VSTDLIB_SRC+= \
		src/vstdlib/keyvaluessystem.cpp \
		src/vstdlib/qsort_s.cpp \
		src/vstdlib/strtools.cpp \
		src/vstdlib/stringnormalize.cpp \
		src/vstdlib/splitstring.cpp \
		src/vstdlib/commandline.cpp

	INTERFACES_SRC= 

	BINLAUNCH_SRC = 

else

	TIER0_SRC+= \
		src/tier0/platform_posix.cpp \
		src/tier0/pme_posix.cpp \
		src/tier0/commandline.cpp \
		src/tier0/win32consoleio.cpp \
		src/tier0/logging.cpp \
		src/tier0/tier0_strtools.cpp

	TIER1_SRC+= \
		src/tier1/utlstring.cpp \
		src/tier1/tier1.cpp \
		src/tier1/characterset.cpp \
		src/tier1/splitstring.cpp \
		src/tier1/strtools.cpp \
		src/tier1/exprevaluator.cpp \

	VSTDLIB_SRC+= \
		src/vstdlib/keyvaluessystem.cpp

	INTERFACES_SRC= \
		src/interfaces/interfaces.cpp

	BINLAUNCH_SRC = \

endif


SRC:=$(VPC_SRC) $(TIER0_SRC) $(TIER1_SRC) $(VSTDLIB_SRC) $(INTERFACES_SRC) $(BINLAUNCH_SRC)


# -----Begin user-editable area-----

# -----End user-editable area-----

# If no configuration is specified, "Debug" will be used
ifndef "CFG"
	CFG:=release
endif


#
# Configuration: Debug
#
ifeq "$(CFG)" "Debug"
	OUTDIR:=obj/$(OS)/debug
	CONFIG_DEPENDENT_FLAGS:=-O0 -g3 -ggdb
else
	OUTDIR:=obj/$(OS)/release
	CONFIG_DEPENDENT_FLAGS:=-O3 -g1 -ggdb
endif

OBJS:=$(addprefix $(OUTDIR)/, $(subst src, ,$(SRC:.cpp=.o)))


OUTFILE:=$(OUTDIR)/vpc
CFG_INC:=-Isrc/public -Isrc/common -Isrc/public/tier0 \
	-I.src/public/tier1 -I.src/public/tier2 -I.src/public/vstdlib


CFLAGS=-D_POSIX -DPOSIX -DGNUC -DNDEBUG $(CONFIG_DEPENDENT_FLAGS) -msse -mmmx -pipe -w -fpermissive -fPIC $(CFG_INC)
ifeq "$(STEAM_BRANCH)" "1"
	CFLAGS+= -DSTEAM
endif


ifeq "$(OS)" "Darwin"
	CFLAGS+=-I$(SDKROOT)/usr/include/malloc
	CFLAGS+= -DOSX -D_OSX
	CFLAGS+= -arch i386 -fasm-blocks
endif

ifeq "$(OS)" "Linux"
	CFLAGS+= -DPLATFORM_LINUX -D_LINUX -DLINUX -m32
endif

ifeq ($(CYGWIN),1)
	CFLAGS+=-D_CYGWIN -DCYGWIN -D_CYGWIN_WINDOWS_TARGET
endif

CFLAGS+= -DCOMPILER_GCC

# the sed magic here adds the dependency file to the list of things that depend on the computed dependency
# set, so if any of them change, the dependencies are re-made
MAKEDEPEND=$(CXX) -M -MT $@ -MM $(CFLAGS) $< | sed -e 's@^\(.*\)\.o:@\1.d \1.o:@' > $(@:.o=.d)
COMPILE=$(CXX) -c $(CFLAGS) -o $@ $<
LINK=$(CXX) $(CONFIG_DEPENDENT_FLAGS)  -o "$(OUTFILE)" $(OBJS) -ldl -lpthread

ifeq "$(OS)" "Darwin"
	LINK+=-liconv -framework Foundation
endif

ifeq "$(OS)" "Darwin"
	LINK+= -arch i386
endif

ifeq "$(OS)" "Linux"
	LINK+= -m32
endif

# Build rules
all: $(OUTFILE) src/devtools/bin/vpc$(EXE_POSTFIX)

src/devtools/bin/vpc$(EXE_POSTFIX) : $(OUTFILE)
	cp "$(OUTFILE)" src/devtools/bin/vpc$(EXE_POSTFIX)

$(OUTFILE): Makefile $(OBJS)
	$(LINK)


# Rebuild this project
rebuild: cleanall all

# Clean this project
clean:
	$(RM) -f $(OUTFILE)
	$(RM) -f $(OBJS)
	$(RM) -f $(OBJS:.o=.d)
	$(RM) -f src/devtools/bin/vpc$(EXE_POSTFIX)

# Clean this project and all dependencies
cleanall: clean

# magic rules - tread with caution
-include $(OBJS:.o=.d)

# Pattern rules
$(OUTDIR)/%.o : %.cpp
	-$(MKDIR) -p $(@D)
	@$(MAKEDEPEND);
	$(COMPILE)

$(OUTDIR)/tier0/%.o : src/tier0/%.cpp
	-$(MKDIR) -p $(@D)
	@$(MAKEDEPEND);
	$(COMPILE)

$(OUTDIR)/tier1/%.o : src/tier1/%.cpp
	-$(MKDIR) -p $(@D)
	@$(MAKEDEPEND);
	$(COMPILE)

$(OUTDIR)/vstdlib/%.o : src/vstdlib/%.cpp
	-$(MKDIR) -p $(@D)
	@$(MAKEDEPEND);
	$(COMPILE)

$(OUTDIR)/interfaces/%.o : src/interfaces/%.cpp
	if [ ! -d $(@D) ]; then $(MKDIR) $(@D); fi
	@$(MAKEDEPEND);
	$(COMPILE)

$(OUTDIR)/utils/binlaunch/%.o : src/binlaunch/%.cpp
	if [ ! -d $(@D) ]; then $(MKDIR) $(@D); fi
	@$(MAKEDEPEND);
	$(COMPILE)


# the tags file) seems like more work than it's worth.  feel free to fix that up
# if it bugs you. 
TAGS:
	@find . -name '*.cpp' -print0 | xargs -0 etags --declarations --ignore-indentation
	@find . -name '*.h' -print0 | xargs -0 etags --language=c++ --declarations --ignore-indentation --append
	@find . -name '*.c' -print0 | xargs -0 etags --declarations --ignore-indentation --append

