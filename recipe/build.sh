#! /usr/bin/env bash

set -x

cd src

go-licenses save ./cmd/skopeo --save_path="../library_licenses"

make -C . install \
    DISABLE_CGO="1" \
    CONTAINERSCONFDIR="${PREFIX}/share/containers" \
    LOOKASIDEDIR="${PREFIX}/etc/containers/sigstore" \
    GIT_COMMIT=
