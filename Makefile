# Why Makefile? - https://makefile.site

.PHONY: app test spec lib docs bin config db tmp

# ===========================================
# makes it possible to run "make aaa bbb" instead of "make aaa ARGS=bbb"
ARGS = $(filter-out $@,$(MAKECMDGOALS))
%:
  @:
# https://stackoverflow.com/a/47008498
# ===========================================

include make-gitflow.mk
include make-basic.mk
include make-db.mk
include make-docker.mk
-include make-personal.mk
