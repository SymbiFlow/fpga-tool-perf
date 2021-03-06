# Copyright (C) 2020  The SymbiFlow Authors.
#
# Use of this source code is governed by a ISC-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/ISC
#
# SPDX-License-Identifier: ISC

SHELL = bash

PWD = $(shell pwd)
INSTALL_DIR = ${PWD}/third_party/install

MULTIPLE_RUN_ITERATIONS ?= 2

all: format

TOP_DIR := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
TOOLCHAIN ?= symbiflow
REQUIREMENTS_FILE ?= conf/${TOOLCHAIN}/requirements.txt
ENVIRONMENT_FILE ?= conf/${TOOLCHAIN}/environment.yml

SYMBIFLOW_ARCHIVE = symbiflow.tar.xz
SYMBIFLOW_LATEST_URL_BASE = https://storage.googleapis.com/symbiflow-arch-defs-gha
SYMBIFLOW_LATEST_URL = ${SYMBIFLOW_LATEST_URL_BASE}/symbiflow-toolchain-latest
SYMBIFLOW_DEVICES = xc7a50t xc7a100t xc7a200t xc7z010 xc7z020

QUICKLOGIC_ARCHIVE = quicklogic.tar.xz
QUICKLOGIC_URL = https://quicklogic-my.sharepoint.com/:u:/p/kkumar/EWuqtXJmalROpI2L5XeewMIBRYVCY8H4yc10nlli-Xq79g?download=1

third_party/make-env/conda.mk:
	git submodule init
	git submodule update --init --recursive

include third_party/make-env/conda.mk

env:: | $(CONDA_ENV_PYTHON)

install_symbiflow: | $(CONDA_ENV_PYTHON)
	mkdir -p env/symbiflow
	curl -s ${SYMBIFLOW_LATEST_URL} | xargs wget -qO- | tar -xJC env/symbiflow
	# Adapt the environment file from symbiflow-arch-defs
	test -e env/symbiflow/environment.yml && sed -i 's/symbiflow_arch_def_base/symbiflow-env/g' env/symbiflow/environment.yml || true
	cat conf/common/requirements.txt conf/symbiflow/requirements.txt > env/symbiflow/requirements.txt
	@$(IN_CONDA_ENV_BASE) conda env update --name symbiflow-env --file env/symbiflow/environment.yml
	# Install all devices
	for device in ${SYMBIFLOW_DEVICES}; do \
		curl -s ${SYMBIFLOW_LATEST_URL_BASE}/symbiflow-$${device}_test-latest | xargs wget -qO- | tar -xJC env/symbiflow; \
	done

install_quicklogic:
	mkdir -p env/quicklogic
	wget -O ${QUICKLOGIC_ARCHIVE} ${QUICKLOGIC_URL}
	tar -xf ${QUICKLOGIC_ARCHIVE} -C env/quicklogic
	rm ${QUICKLOGIC_ARCHIVE}

PYTHON_SRCS=$(shell find . -name "*py" -not -path "./third_party/*" -not -path "./env/*" -not -path "./conf/*")

format: ${PYTHON_SRCS}
	yapf -i $?

clean::
	rm -rf build/

.PHONY: all env build-tools format run-all clean
