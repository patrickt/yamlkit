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
all: source

# ***************************************************************************
# yaml
# ***************************************************************************
ifdef HAVE_SCM
libyaml:
	$(SVN) co $(YAML_LIB_SVN_URL) -r $(YAML_LIB_SVN_REVISION) $@

.libyaml: libyaml
	(cd $<; ./bootstrap && ./configure --prefix=$(PREFIX) && make && make install)
	touch $@
else
yaml-$(YAML_LIB_VERSION).tar.gz:
	$(WGET) $(YAML_LIB_URL)

libyaml: yaml-$(YAML_LIB_VERSION).tar.gz
	$(EXTRACT_GZ)

.libyaml: libyaml
	(cd $<; ./configure --prefix=$(PREFIX) && make && make install)
	touch $@
endif

SOURCE += libyaml
CLEAN_FILE += .libyaml
CLEAN_PKG += libyaml

# ***************************************************************************
# yaml
# ***************************************************************************
clean-dots:
	rm -f $(CLEAN_FILE)

clean: clean-dots
	rm -rf $(CLEAN_PKG)

clean-all: clean
	rm -rf ../lib
	rm -rf ../include

source: $(CLEAN_FILE)
