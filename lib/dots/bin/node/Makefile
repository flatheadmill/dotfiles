javascript := $(filter-out _%, $(wildcard *.js))
javascript += $(filter-out _%, $(wildcard *.*/*.js))
javascript += $(filter-out _%, $(wildcard t/*.js))
javascript += $(filter-out _%, $(wildcard *.*/t/*.js))

makefile_list_last := $(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST))

all: coverage/coverage-summary._json

coverage/coverage-summary._json: node_modules/.bin/istanbul $(javascript)
	[[ -e t/cover ]] && t/cover || $(dir $(makefile_list_last))cover.bash
	node_modules/.bin/istanbul report --format json-summary 
	mv coverage/coverage-summary.json coverage/coverage-summary._json


node_modules/.bin/istanbul:
	mkdir -p node_modules
	npm install istanbul

clean:
	rm -rf coverage
