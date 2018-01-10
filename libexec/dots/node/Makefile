javascript := $(filter-out _%, $(wildcard *.js))
javascript += $(filter-out _%, $(wildcard *.*/*.js))
javascript += $(filter-out _%, $(wildcard t/*.js))
javascript += $(filter-out _%, $(wildcard *.*/t/*.js))

makefile_list_last := $(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST))

all: coverage/coverage-summary._json

coverage/coverage-summary._json: $(javascript)
	[[ -e t/cover ]] && t/cover || $(dir $(makefile_list_last))_cover.bash
	istanbul report --format json-summary
	mv coverage/coverage-summary.json coverage/coverage-summary._json

clean:
	rm -rf coverage
