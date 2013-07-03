# based on the Makefile for jquery

SRC_DIR = src
TEST_DIR = test
BUILD_DIR = build

PREFIX = .
DIST_DIR = ${PREFIX}/dist
COMPILED_DOCS_DIR = ${PREFIX}/compiled_docs

JS_ENGINE ?= `which node nodejs`
COMPILER = ${JS_ENGINE} ${BUILD_DIR}/uglify.js --unsafe
POST_COMPILER = ${JS_ENGINE} ${BUILD_DIR}/post-compile.js
DOCCO ?= `which docco-husky`
GRUNT ?= `which grunt`
COFFEE ?= `which coffee`

BASE_FILES = ${SRC_DIR}/core.coffee \
			${SRC_DIR}/data.coffee \
			${SRC_DIR}/importer.coffee \
			${SRC_DIR}/expression.coffee \
			${SRC_DIR}/presentation.coffee \
			${SRC_DIR}/facet.coffee \
			${SRC_DIR}/controller.coffee \
			${SRC_DIR}/application.coffee \
			${SRC_DIR}/plugin.coffee

MODULES = ${SRC_DIR}/intro.coffee \
		${BASE_FILES} \
		${SRC_DIR}/outro.coffee

MG = ${DIST_DIR}/mithgrid.js
MG_MIN = ${DIST_DIR}/mithgrid.min.js
MG_C = ${DIST_DIR}/mithgrid.coffee

MG_VER = $(shell cat version.txt)
VER = sed "s/@VERSION/${MG_VER}/"

MG_MAJOR = $(shell cat version.txt)
MG_MINOR = $(shell date +%y%j)
N ?= 0

VER = sed "s/@VERSION/${MG_MAJOR}.${MG_MINOR}${N}/"


DATE=$(shell git log --pretty=format:%ad | head -1)

all: core docs

core: mithgrid min lint test
	@@echo "mithgrid build complete"

${DIST_DIR}:
	@@mkdir -p ${DIST_DIR}

${COMPILED_DOCS_DIR}/src:
	@@mkdir -p ${COMPILED_DOCS_DIR}/src

docs: ${MODULES} ${COMPILED_DOCS_DIR}/src README.md
	@@${DOCCO} ${SRC_DIR}

test: mithgrid
	@@if test ! -z ${GRUNT}; then \
		echo "Testing mithgrid"; \
		${COFFEE} -c ${TEST_DIR}; \
		${GRUNT} qunit; \
	else \
		echo "You must have grunt installed in order to test mithgrid."; \
	fi

package.json: package.json.in
	@@cat package.json.in | ${VER} > package.json

mithgrid: ${MG}

${MG_C}: ${MODULES} ${DIST_DIR}
	@@echo "Building" ${MG_C}
	
	@@rm -f ${MG_C}.tmp
	@@for i in ${BASE_FILES}; do \
		cat $$i | sed 's/^/  /' >> ${MG_C}.tmp; \
		echo >> ${MG_C}.tmp; \
		done
	
	@@cat ${SRC_DIR}/intro.coffee ${MG_C}.tmp ${SRC_DIR}/outro.coffee | \
		sed 's/@DATE/'"${DATE}"'/' | \
		${VER} > ${MG_C};
	@@rm -f ${MG_C}.tmp;

${MG}: ${MG_C}
	@@${COFFEE} -c ${MG_C};

lint: mithgrid
	@@if test ! -z ${JS_ENGINE}; then \
		echo "Checking mithgrid against JSLint..."; \
		${JS_ENGINE} build/jslint-check.js; \
	else \
		echo "You must have NodeJS installed in order to test mithgrid against JSLint."; \
	fi

min: mithgrid ${MG_MIN}

#echo "/*" > ${MG_MIN}; \
#cat ${MG_C} | \
#	awk '/###/ { i = i + 1; l = 0; j = j + 1 }; l = l + 1 { }; (i ~ 1 && l !~ 1 && j < 3) { print  }' | \
#	sed 's/^#/ */' >> ${MG_MIN}; \
#echo " */" >> ${MG_MIN}; \
		
${MG_MIN}: ${MG}
	@@if test ! -z ${JS_ENGINE}; then \
		echo "Minifying mithgrid" ${MG_MIN}; \
		${COMPILER} ${MG} | \
		sed 's/^#/ */' > ${MG_MIN}.tmp; \
		${POST_COMPILER} ${MG_MIN}.tmp > ${MG_MIN}; \
		rm -f ${MG_MIN}.tmp; \
	else \
		echo "You must have NodeJS installed in order to minify mithgrid."; \
	fi

clean:
	@@echo "Removing Distribution directory:" ${DIST_DIR}
	@@rm -rf ${DIST_DIR}
	@@echo "Removing compiled test scripts:" ${TEST_DIR}/*.js
	@@rm -f ${TEST_DIR}/*.js
	@@echo "Removing compiled documentation: " ${COMPILED_DOCS_DIR}
	@@rm -rf ${COMPILED_DOCS_DIR}

distclean: clean

.PHONY: all mithgrid lint min clean distclean core
