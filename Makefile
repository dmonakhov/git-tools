#PREFIX?=/usr/local
PREFIX?=~/.local
DESTDIR?=
INSTALL?=install

GIT_SCRIPTS = $(filter-out $(wildcard *~),$(wildcard git-*))
UTIL_SCRIPTS = $(filter-out $(wildcard *~),$(wildcard ./utils/*))

.PHONY: all 
all:
	@echo "Nothing to build, it is all bash :)"
	@echo "Try make install"

.PHONY: install
install:
	$(INSTALL) -d $(DESTDIR)$(PREFIX)/bin/
	$(INSTALL) -m 755 $(GIT_SCRIPTS) $(DESTDIR)$(PREFIX)/bin
	$(INSTALL) -m 755 $(UTIL_SCRIPTS) $(DESTDIR)$(PREFIX)/bin


