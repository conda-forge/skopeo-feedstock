#! /usr/bin/env bash

set -x

cd src

go-licenses save ./cmd/skopeo --save_path="../library_licenses"

disable_cgo=0
if ! [[ ${target_platform} =~ linux.* ]] ; then
    disable_cgo=1
fi

make -C . install \
        DISABLE_CGO="${disable_cgo}" \
        CONTAINERSCONFDIR="${PREFIX}/share/containers" \
        LOOKASIDEDIR="${PREFIX}/etc/containers/sigstore" \
        GIT_COMMIT=
