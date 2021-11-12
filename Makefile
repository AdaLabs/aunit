RTS =
TARGET =
GPRBUILD  = gprbuild
GPRCLEAN = gprclean
GPRINSTALL = gprinstall

prefix?=$(dir $(shell which gnatls))..
DESTDIR?=
INSTALL:=$(DESTDIR)$(prefix)

ifeq ($(RTS),)
   RTS=full
   RTS_CONF =
else
   RTS_CONF = --RTS=$(RTS)
endif

ifeq ($(TARGET),)
   TARGET=native
   TARGET_CONF =
else
   TARGET_CONF = --target=$(TARGET)
endif

MODE = Install

CONF_ARGS = $(TARGET_CONF) $(RTS_CONF)

GPROPTS = $(CONF_ARGS) -XAUNIT_BUILD_MODE=$(MODE) -XAUNIT_RUNTIME=$(RTS) \
		-XAUNIT_PLATFORM=$(TARGET)

.PHONY: all clean targets install_clean install

all:
	$(GPRBUILD) -p $(GPROPTS) lib/gnat/aunit.gpr

clean-lib:
	$(RM) -fr lib/aunit lib/aunit-obj

clean: clean-lib
	-${MAKE} -C docs clean

install-clean-legacy:
ifneq (,$(wildcard $(INSTALL)/lib/gnat/manifests/aunit))
	-$(GPRINSTALL) $(GPROPTS) --uninstall --prefix=$(INSTALL) \
		--project-subdir=lib/gnat aunit
endif

install-clean: install-clean-legacy
ifneq (,$(wildcard $(INSTALL)/share/gpr/manifests/aunit))
	-$(GPRINSTALL) $(GPROPTS) --uninstall --prefix=$(INSTALL) aunit
endif

install-static:clean
	gprclean -f -P lib/gnat/aunit.gpr $(GPROPTS) -XLIBRARY_TYPE=static
	gprbuild -p -P lib/gnat/aunit.gpr $(GPROPTS) -XLIBRARY_TYPE=static
	mkdir -p $(DESTDIR)$(prefix)/bin
	gprinstall $(GPROPTS) -f -p -P lib/gnat/aunit.gpr --prefix=$(DESTDIR)$(prefix) --build-name=default  -XLIBRARY_TYPE=static

install-static-rts-adalabs:clean
	gprclean -f -P lib/gnat/aunit.gpr $(GPROPTS) -XLIBRARY_TYPE=static -XRTS_TYPE=default
	gprbuild -p -P lib/gnat/aunit.gpr $(GPROPTS) -XLIBRARY_TYPE=static -XRTS_TYPE=adalabs --RTS=adalabs
	gprinstall $(GPROPTS) -f -p -P lib/gnat/aunit.gpr --prefix=$(DESTDIR)$(prefix) --build-name=rts-adalabs -XLIBRARY_TYPE=static -XRTS_TYPE=adalabs --RTS=adalabs
	sed -i '1s/^/with \"rts\"\;\n/' $(DESTDIR)$(prefix)/share/gpr/aunit.gpr
	sed -i 's/case BUILD is/case RTS.RTS_Type is/' $(DESTDIR)$(prefix)/share/gpr/aunit.gpr
	sed -i 's/type BUILD_KIND is (\"default\", \"rts-adalabs\")\;//' $(DESTDIR)$(prefix)/share/gpr/aunit.gpr
	sed -i 's/BUILD : BUILD_KIND := external(\"AUNIT_BUILD\", \"default\")\;//' $(DESTDIR)$(prefix)/share/gpr/aunit.gpr
	sed -i 's/\"rts-adalabs\"/\"adalabs\"/' $(DESTDIR)$(prefix)/share/gpr/aunit.gpr


install: install-clean
	make install-static
	make install-static-rts-adalabs


.PHONY: doc
doc:
	${MAKE} -C doc

RM	= rm
