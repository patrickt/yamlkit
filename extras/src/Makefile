# ***************************************************************************
# extras/src/Makefile
# ***************************************************************************
include ../config.mak
include ./packages.mak

# ***************************************************************************
# Useful macros
# ***************************************************************************
define EXTRACT_GZ
	rm -rf $@ || true
	$(GUNZIP) -c $< | $(TAR) xf - --exclude='[*?:<>\|]'
	mv $(patsubst %.tar.gz,%,$(patsubst %.tgz,%,$(notdir $<))) $@ || true
	touch $@
endef

define EXTRACT_BZ2
	rm -rf $@ || true
	$(BUNZIP2) -c $< | $(TAR) xf - --exclude='[*?:<>\|]'
	mv $(patsubst %.tar.bz2,%,$(notdir $<)) $@ || true
	touch $@
endef

define EXTRACT_ZIP
	rm -rf $@ || true
	$(UNZIP) $<
	mv $(patsubst %.zip,%,$(notdir $<)) $@ || true
	touch $@
endef

# ***************************************************************************
# Rules
# ***************************************************************************
all: library
FLAGS=CFLAGS="-arch ppc -arch i386 -arch x86_64" --disable-dependency-tracking --prefix=$(PREFIX)

# ***************************************************************************
# yaml
# ***************************************************************************
ifdef HAVE_SCM
libyaml:
	$(SVN) co $(YAML_LIB_SVN_URL) -r $(YAML_LIB_SVN_REVISION) $@

.libyaml: libyaml
	(cd $<; ./bootstrap && ./configure $(FLAGS)  && make && make install)
	touch $@
else
yaml-$(YAML_LIB_VERSION).tar.gz:
	$(WGET) $(YAML_LIB_URL)

libyaml: yaml-$(YAML_LIB_VERSION).tar.gz
	$(EXTRACT_GZ)

.libyaml: libyaml
	(cd $<;  ./configure $(FLAGS) && make && make install)
	touch $@

CLEAN_DISTRO += yaml-$(YAML_LIB_VERSION).tar.gz
endif

CLEAN_FILE += .libyaml
CLEAN_PKG += libyaml

# ***************************************************************************
# RegexKitLite
# ***************************************************************************
ifdef HAVE_SCM
regexlite:
	$(SVN) co $(REGEX_KIT_LITE_SVN_URL) -r $(REGEX_KIT_LITE_SVN_REVISION) $@

else
RegexKitLite-$(REGEX_KIT_LITE_VERSION).tar.bz2:
	$(WGET) $(REGEX_KIT_LITE_URL)

regexlite: RegexKitLite-$(REGEX_KIT_LITE_VERSION).tar.bz2
	$(EXTRACT_BZ2)

CLEAN_DISTRO += RegexKitLite-$(REGEX_KIT_LITE_VERSION).tar.bz2
endif

.regexlite: regexlite
	touch $@

CLEAN_FILE += .regexlite
CLEAN_PKG += regexlite

# ***************************************************************************
# Compile
# ***************************************************************************
source: $(CLEAN_PKG)
library: $(CLEAN_DISTRO) $(CLEAN_FILE)

# ***************************************************************************
# cleanup
# ***************************************************************************
clean-dots:
	rm -f $(CLEAN_FILE)

clean: clean-dots
	rm -rf $(CLEAN_PKG)

clean-all: clean
	rm -f $(CLEAN_DISTRO)
	rm -rf ../lib
	rm -rf ../include
