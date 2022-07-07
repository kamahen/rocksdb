#COFLAGS=-gdwarf-2 -g3
CPPFLAGS=-std=c++17 -O2 $(CFLAGS) $(COFLAGS) $(LDSOFLAGS) -Irocksdb/include
LIBROCKSDB=rocksdb/librocksdb.a
ROCKSENV=ROCKSDB_DISABLE_JEMALLOC=1 ROCKSDB_DISABLE_TCMALLOC=1
# DEBUG_LEVEL=0 implies -O2 without assertions and debug code
ROCKSCFLAGS=EXTRA_CXXFLAGS=-fPIC EXTRA_CFLAGS=-fPIC USE_RTTI=1 DEBUG_LEVEL=0
PLPATHS=-p library=prolog -p foreign="$(PACKSODIR)"

# sets PLATFORM_LDFLAGS
-include rocksdb/make_config.mk

all:	plugin

.PHONY: FORCE all clean install check distclean realclean shared_object plugin

rocksdb/INSTALL.md: FORCE
	git submodule update --init rocksdb

# Run the build for librocksdb in parallel, using # processors as
# limit, if using GNU make
JOBS=$(shell $(MAKE) --version 2>/dev/null | grep GNU >/dev/null && J=$$(nproc 2>/dev/null) && echo -j$$J)
rocksdb/librocksdb.a: rocksdb/INSTALL.md FORCE
	$(ROCKSENV) $(MAKE) $(JOBS) -C rocksdb static_lib $(ROCKSCFLAGS)

plugin:	$(LIBROCKSDB)
	$(MAKE) shared_object

shared_object: $(PACKSODIR)/rocksdb4pl.$(SOEXT)

$(PACKSODIR)/rocksdb4pl.$(SOEXT): cpp/rocksdb4pl.cpp $(LIBROCKSDB) Makefile
	mkdir -p $(PACKSODIR)
	$(CXX) $(CPPFLAGS) -shared -o $@ cpp/rocksdb4pl.cpp $(LIBROCKSDB) $(PLATFORM_LDFLAGS) $(SWISOLIB)

install::

check::
	swipl $(PLPATHS) -g test_rocksdb -t halt test/test_rocksdb.pl

distclean: clean
	rm -f $(PACKSODIR)/rocksdb4pl.$(SOEXT)

clean:
	rm -f *~

realclean: distclean
	git -C rocksdb clean -xfd
