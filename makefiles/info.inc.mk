.PHONY: info-objsize info-buildsizes info-build info-boards-supported \
        info-features-missing info-modules info-cpu

info-objsize:
	@case "${SORTROW}" in \
	  text) SORTROW=1 ;; \
	  data) SORTROW=2 ;; \
	  bss) SORTROW=3 ;; \
	  dec) SORTROW=4 ;; \
	  "") SORTROW=4 ;; \
	  *) echo "Usage: $(MAKE) info-objsize SORTROW=[text|data|bss|dec]" ; return ;; \
	esac; \
	echo -e '   text\t   data\t    bss\t    dec\t    hex\tfilename'; \
	$(SIZE) -d -B $(BASELIBS) | \
	  tail -n+2 | \
	  sed -e 's#$(BINDIR)##' | \
	  sort -rnk$${SORTROW}

info-buildsize:
	@$(SIZE) -d -B $(BINDIR)/$(APPLICATION).elf || echo ''

info-build:
	@echo 'APPLICATION: $(APPLICATION)'
	@echo ''
	@echo 'supported boards:'
	@echo $$($(MAKE) info-boards-supported)
	@echo ''
	@echo 'BOARD:   $(BOARD)'
	@echo 'CPU:     $(CPU)'
	@echo 'MCU:     $(MCU)'
	@echo ''
	@echo 'RIOTBASE:  $(RIOTBASE)'
	@echo 'RIOTBOARD: $(RIOTBOARD)'
	@echo 'RIOTCPU:   $(RIOTCPU)'
	@echo 'RIOTPKG:   $(RIOTPKG)'
	@echo ''
	@echo 'DEFAULT_MODULE: $(sort $(filter-out $(DISABLE_MODULE), $(DEFAULT_MODULE)))'
	@echo 'DISABLE_MODULE: $(sort $(DISABLE_MODULE))'
	@echo 'USEMODULE:      $(sort $(filter-out $(DEFAULT_MODULE), $(USEMODULE)))'
	@echo ''
	@echo 'ELFFILE: $(ELFFILE)'
	@echo 'HEXFILE: $(HEXFILE)'
	@echo ''
	@echo 'FEATURES_REQUIRED (excl. optional features):'
	@echo '         $(or $(sort $(filter-out $(FEATURES_OPTIONAL), $(FEATURES_REQUIRED))), -none-)'
	@echo 'FEATURES_OPTIONAL (strictly "nice to have"):'
	@echo '         $(or $(sort $(FEATURES_OPTIONAL)), -none-)'
	@echo 'FEATURES_PROVIDED (by the board or USEMODULE'"'"'d drivers):'
	@echo '         $(or $(sort $(FEATURES_PROVIDED)), -none-)'
	@echo 'FEATURES_MISSING (incl. optional features):'
	@echo '         $(or $(sort $(filter-out $(FEATURES_PROVIDED), $(FEATURES_REQUIRED))), -none-)'
	@echo 'FEATURES_MISSING (only non-optional features):'
	@echo '         $(or $(sort $(filter-out $(FEATURES_OPTIONAL) $(FEATURES_PROVIDED), $(FEATURES_REQUIRED))), -none-)'
	@echo ''
	@echo 'FEATURES_CONFLICT:     $(FEATURES_CONFLICT)'
	@echo 'FEATURES_CONFLICT_MSG: $(FEATURES_CONFLICT_MSG)'
	@echo ''
	@echo 'CC:      $(CC)'
	@echo -e 'CFLAGS:$(patsubst %, \n\t%, $(CFLAGS))'
	@echo ''
	@echo 'CXX:     $(CXX)'
	@echo -e 'CXXUWFLAGS:$(patsubst %, \n\t%, $(CXXUWFLAGS))'
	@echo -e 'CXXEXFLAGS:$(patsubst %, \n\t%, $(CXXEXFLAGS))'
	@echo ''
	@echo 'LINK:    $(LINK)'
	@echo -e 'LINKFLAGS:$(patsubst %, \n\t%, $(LINKFLAGS))'
	@echo ''
	@echo 'OBJCOPY: $(OBJCOPY)'
	@echo 'OFLAGS:  $(OFLAGS)'
	@echo ''
	@echo 'FLASHER: $(FLASHER)'
	@echo 'FFLAGS:  $(FFLAGS)'
	@echo ''
	@echo 'TERMPROG:  $(TERMPROG)'
	@echo 'TERMFLAGS: $(TERMFLAGS)'
	@echo 'PORT:      $(PORT)'
	@echo ''
	@echo 'DEBUGGER:       $(DEBUGGER)'
	@echo 'DEBUGGER_FLAGS: $(DEBUGGER_FLAGS)'
	@echo
	@echo 'DOWNLOAD_TO_FILE:   $(DOWNLOAD_TO_FILE)'
	@echo 'DOWNLOAD_TO_STDOUT: $(DOWNLOAD_TO_STDOUT)'
	@echo 'UNZIP_HERE:         $(UNZIP_HERE)'
	@echo ''
	@echo 'DEBUGSERVER:       $(DEBUGSERVER)'
	@echo 'DEBUGSERVER_FLAGS: $(DEBUGSERVER_FLAGS)'
	@echo ''
	@echo 'RESET:       $(RESET)'
	@echo 'RESET_FLAGS: $(RESET_FLAGS)'
	@echo ''
	@echo -e 'MAKEFILE_LIST:$(patsubst %, \n\t%, $(abspath $(MAKEFILE_LIST)))'

ifneq (, $(filter buildtest info-concurrency, $(MAKECMDGOALS)))
  ifeq (, $(strip $(NPROC)))
    # Linux (utility program)
    NPROC := $(shell nproc 2>/dev/null)

    ifeq (, $(strip $(NPROC)))
      # Linux (generic)
      NPROC := $(shell grep -c ^processor /proc/cpuinfo 2>/dev/null)
    endif
    ifeq (, $(strip $(NPROC)))
      # BSD (at least FreeBSD and Mac OSX)
      NPROC := $(shell sysctl -n hw.ncpu 2>/dev/null)
    endif
    ifeq (, $(strip $(NPROC)))
      # Fallback
      NPROC := 1
    endif

    NPROC := $(shell echo $$(($(NPROC) + 1)))

    ifneq (, $(NPROC_MAX))
      NPROC := $(shell if [ ${NPROC} -gt $(NPROC_MAX) ]; then echo $(NPROC_MAX); else echo ${NPROC}; fi)
    endif
    ifneq (, $(NPROC_MIN))
      NPROC := $(shell if [ ${NPROC} -lt $(NPROC_MIN) ]; then echo $(NPROC_MIN); else echo ${NPROC}; fi)
    endif
  endif
endif

info-concurrency:
	@echo "$(NPROC)"

info-files: QUIET := 0
info-files:
	@( \
	  echo "$(abspath $(shell echo "$(MAKEFILE_LIST)"))" | tr ' ' '\n'; \
	  CSRC="$$($(MAKE) USEPKG="" -Bn | grep -o -e "[^ ]\+\.[csS]$$" -e "[^ ]\+\.[csS][ \']" | grep -v -e "^\s*-D")"; \
	  echo "$$CSRC"; \
	  echo "$(RIOTBASE)/Makefile.base"; \
	  echo "$$CSRC" | xargs dirname -- | sort | uniq | xargs -I{} find {} -name "Makefile*"; \
	  echo "$$CSRC" | xargs $(CC) $(CFLAGS) $(INCLUDES) -MM 2> /dev/null | grep -o "[^ ]\+\.h"; \
	  if [ -n "$$SRCXX" ]; then \
	    CPPSRC="$$($(MAKE) -Bn USEPKG="" | grep -o -e "[^ ]\+\.cpp" | grep -v -e "^\s*-D")"; \
	    echo "$$CPPSRC"; \
	    echo "$$CPPSRC" | xargs dirname -- | sort | uniq | xargs -I{} find {} -name "Makefile*"; \
	    echo "$$CPPSRC" | xargs $(CXX) $(CXXFLAGS) $(INCLUDES) -MM 2> /dev/null | grep -o "[^ ]\+\.h"; \
	  fi; \
	  $(foreach pkg,$(USEPKG),find $(RIOTPKG)/$(pkg) -type f;) \
	) | sort | uniq | sed 's#$(RIOTBASE)/##'

info-modules:
	@for i in $(sort $(USEMODULE)); do echo $$i; done

info-cpu:
	@echo $(CPU)

info-features-missing:
	@echo $(filter-out $(FEATURES_PROVIDED), $(FEATURES_REQUIRED))
