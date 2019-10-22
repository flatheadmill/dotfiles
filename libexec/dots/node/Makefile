javascript := $(filter-out _%, $(wildcard *.js))
javascript += $(filter-out _%, $(wildcard *.*/*.js))
javascript += $(filter-out _%, $(wildcard t/*.js))
javascript += $(filter-out _%, $(wildcard *.*/t/*.js))

makefile_list_last := $(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST))

all: coverage/coverage-summary._json

coverage/coverage-summary._json: $(javascript)
	nyc npm test
	nyc report --reporter json-summary
	mv coverage/coverage-summary.json coverage/coverage-summary._json

clean:
	rm -rf coverage
