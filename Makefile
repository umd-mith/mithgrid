# based on the Makefile for jquery

SRC_DIR = src
TEST_DIR = test
BUILD_DIR = build

PREFIX = .
DIST_DIR = ${PREFIX}/dist

JS_ENGINE ?= `which node nodejs`
COMPILER = ${JS_ENGINE} ${BUILD_DIR}/uglify.js --unsafe
POST_COMPILER = ${JS_ENGINE} ${BUILD_DIR}/post-compile.js

BASE_FILES = ${SRC_DIR}/core.js \
			${SRC_DIR}/data.js \
			${SRC_DIR}/expression.js \
			${SRC_DIR}/presentation.js \
			${SRC_DIR}/application.js

MODULES = ${SRC_DIR}/intro.js \
		${BASE_FILES} \
		${SRC_DIR}/outro.js

MG = ${DIST_DIR}/mithgrid.js
MG_MIN = ${DIST_DIR}/mithgrid.min.js

MG_VER = $(shell cat version.txt)
VER = sed "s/@VERSION/${MG_VER}/"

DATE=$(shell git log -l --pretty=format:%ad)

all: core

core: mithgrid min lint
		@@echo "mithgrid build complete"

${DIST_DIR}:
		@@mkdir -p ${DIST_DIR}

mithgrid: ${MG}

${MG}: ${MODULES} | ${DIST_DIR}
		@@echo "Building" ${MG}
		
		@@cat ${BASE_FILES} | \
			sed 's/.function....MITHGrid..{//' | \
			sed 's/}..jQuery..MITHGrid.;//' | \
			sed 's/@DATE/'"${DATE}"'/' > ${MG}.tmp;
		@@cat ${SRC_DIR}/intro.js ${MG}.tmp ${SRC_DIR}/outro.js | \
			${VER} > ${MG};
		@@rm -f ${MG}.tmp;

lint: mithgrid
		@@if test ! -z ${JS_ENGINE}; then \
				echo "Checking mithgrid against JSLint..."; \
				${JS_ENGINE} build/jslint-check.js; \
		else \
				echo "You must have NodeJS installed in order to test mithgrid against JSLint."; \
		fi

min: mithgrid ${MG_MIN}

${MG_MIN}: ${MG}
		@@if test ! -z ${JS_ENGINE}; then \
				echo "Minifying mithgrid" ${MG_MIN}; \
				${COMPILER} ${MG} > ${MG_MIN}.tmp; \
				${POST_COMPILER} ${MG_MIN}.tmp > ${MG_MIN}; \
				rm -f ${MG_MIN}.tmp; \
		else \
				echo "You must have NodeJS installed in order to minify mithgrid."; \
		fi

clean:
		@@echo "Removing Distribution directory:" ${DIST_DIR}
		@@rm -rf ${DIST_DIR}

distclean: clean

.PHONY: all mithgrid lint min clean distclean core