CXX ?= c++
CC ?= cc
AR ?= ar
HOST_CXX ?= c++
HOST_CXXFLAGS ?= -O2
PKG_CONFIG ?= pkg-config
BUILD ?= .build
PREFIX ?= /usr/local
CATALOGUE := ../catalogue/catalogue.fcr
# Homebrew's ICU is keg-only. Other installations use their normal pkg-config path.
ICU_PC := $(firstword $(wildcard /opt/homebrew/opt/icu4c/lib/pkgconfig /usr/local/opt/icu4c/lib/pkgconfig))
export PKG_CONFIG_PATH := $(ICU_PC):$(PKG_CONFIG_PATH)
ICU_CFLAGS := $(shell PKG_CONFIG_PATH="$(PKG_CONFIG_PATH)" $(PKG_CONFIG) --cflags icu-uc icu-i18n)
ICU_LIBS := $(shell PKG_CONFIG_PATH="$(PKG_CONFIG_PATH)" $(PKG_CONFIG) --libs icu-uc icu-i18n)
CPPFLAGS += -Iinclude -I$(BUILD) $(ICU_CFLAGS)
CXXFLAGS ?= -O2
CXXFLAGS += -std=c++17 -pthread -Wall -Wextra -Wpedantic -fPIC -MMD -MP
LDLIBS += $(ICU_LIBS) -pthread
ifeq ($(shell uname -s),Darwin)
SHARED := $(BUILD)/libfrconjugation.dylib
SHARED_FLAGS := -dynamiclib -Wl,-install_name,@rpath/libfrconjugation.dylib
else
SHARED := $(BUILD)/libfrconjugation.so
SHARED_FLAGS := -shared -Wl,-soname,libfrconjugation.so
endif

.PHONY: all test clean install
all: $(BUILD)/libfrconjugation.a $(SHARED)
$(BUILD):
	mkdir -p $@
$(BUILD)/embed: tools/embed.cpp | $(BUILD)
	$(HOST_CXX) $(HOST_CXXFLAGS) -std=c++17 $< -o $@
$(BUILD)/catalogue.inc: $(CATALOGUE) $(BUILD)/embed | $(BUILD)
	$(BUILD)/embed $< $@
$(BUILD)/engine.o: src/engine.cpp $(BUILD)/catalogue.inc include/frconjugation.h | $(BUILD)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@
$(BUILD)/api.o: src/api.cpp include/frconjugation_api.h include/frconjugation_types.h | $(BUILD)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@
$(BUILD)/grammar.o: src/grammar.cpp include/frconjugation_types.h | $(BUILD)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@
$(BUILD)/libfrconjugation.a: $(BUILD)/engine.o $(BUILD)/api.o $(BUILD)/grammar.o
	$(AR) rcs $@ $^
$(SHARED): $(BUILD)/engine.o $(BUILD)/api.o $(BUILD)/grammar.o
	$(CXX) $(LDFLAGS) $(SHARED_FLAGS) $^ $(LDLIBS) -o $@
$(BUILD)/test: tests/test.cpp $(BUILD)/libfrconjugation.a include/frconjugation.hpp
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $(LDFLAGS) $< $(BUILD)/libfrconjugation.a $(LDLIBS) -o $@
$(BUILD)/c_test.o: tests/c_test.c include/frconjugation.h | $(BUILD)
	$(CC) $(CPPFLAGS) $(CFLAGS) -std=c11 -Wall -Wextra -Werror -c $< -o $@
$(BUILD)/c_test: $(BUILD)/c_test.o $(BUILD)/libfrconjugation.a
	$(CXX) $(LDFLAGS) $^ $(LDLIBS) -o $@
$(BUILD)/conformance: tests/conformance.cpp $(BUILD)/libfrconjugation.a include/frconjugation.hpp
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $(LDFLAGS) $< $(BUILD)/libfrconjugation.a $(LDLIBS) -o $@
$(BUILD)/typed_parity: tests/typed_parity.cpp tests/fixtures.hpp $(BUILD)/libfrconjugation.a include/frconjugation.hpp
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $(LDFLAGS) $< $(BUILD)/libfrconjugation.a $(LDLIBS) -o $@
test: all $(BUILD)/test $(BUILD)/c_test $(BUILD)/conformance $(BUILD)/typed_parity
	$(BUILD)/test
	$(BUILD)/c_test
	$(BUILD)/conformance ../tests/conformance.tsv
	$(BUILD)/typed_parity ../tests/typed-api.tsv
install: all
	install -d $(DESTDIR)$(PREFIX)/include $(DESTDIR)$(PREFIX)/lib
	install -m 644 include/*.h include/*.hpp $(DESTDIR)$(PREFIX)/include/
	install -m 644 $(BUILD)/libfrconjugation.a $(SHARED) $(DESTDIR)$(PREFIX)/lib/
clean:
	rm -rf $(BUILD)
-include $(BUILD)/*.d

# Optional cross-runtime conformance check on hosts with Swift installed.
.PHONY: verify-swift
$(BUILD)/dump: tests/dump.cpp $(BUILD)/libfrconjugation.a include/frconjugation.hpp
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $(LDFLAGS) $< $(BUILD)/libfrconjugation.a $(LDLIBS) -o $@
$(BUILD)/swift-oracle: tests/SwiftOracle.swift ../swift/Sources/FRConjugation/RuleFile.swift ../swift/Sources/FRConjugation/RuleCatalogue.swift ../swift/Sources/FRConjugation/Types.swift | $(BUILD)
	swiftc -O $^ -o $@
verify-swift: $(BUILD)/dump $(BUILD)/swift-oracle
	$(BUILD)/dump > $(BUILD)/native-results.bin
	$(BUILD)/swift-oracle $(CATALOGUE) > $(BUILD)/swift-results.bin
	cmp $(BUILD)/native-results.bin $(BUILD)/swift-results.bin
