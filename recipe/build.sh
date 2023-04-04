#! /usr/bin/env bash

set -x

cp ./src/LICENSE ./
module_path="${GOPATH:-"$( go env GOPATH )"}"/src/github.com/containers/skopeo
mkdir -p "$( dirname "${module_path}" )"
mv ./src "${module_path}"

disable_cgo=0
if ! [[ ${target_platform} =~ linux.* ]] ; then
    disable_cgo=1
fi

export GOOS=$(go env GOOS)
export GOARCH=$(go env GOARCH)

if [[ ${GOARCH} == "arm64" ]] ; then
    pushd "${module_path}"
    
    make bin/skopeo.${GOOS}.${GOARCH} \
        DISABLE_CGO="${disable_cgo}" \
        CONTAINERSCONFDIR="${PREFIX}/share/containers" \
        LOOKASIDEDIR="${PREFIX}/etc/containers/sigstore" \
        GIT_COMMIT=
    install -d -m 755 "${PREFIX}/bin"
    install -m 755 bin/skopeo.${GOOS}.${GOARCH} "${PREFIX}/bin/skopeo"
    make install-docs \
        DISABLE_CGO="${disable_cgo}" \
        CONTAINERSCONFDIR="${PREFIX}/share/containers" \
        LOOKASIDEDIR="${PREFIX}/etc/containers/sigstore" \
        GIT_COMMIT=
    
    popd
else
    make -C "${module_path}" install \
            DISABLE_CGO="${disable_cgo}" \
            CONTAINERSCONFDIR="${PREFIX}/share/containers" \
            LOOKASIDEDIR="${PREFIX}/etc/containers/sigstore" \
            GIT_COMMIT=
fi

export THIRD_PARTY_LICENSES="${PWD}/3rd_party_licenses/"
pushd "${module_path}"
echo "replace github.com/containers/common v0.51.0 => github.com/containers/common v1.0.1" >> go.mod
go mod tidy -compat=1.17
go mod vendor
go-licenses save ./cmd/skopeo --save_path="${THIRD_PARTY_LICENSES}"
popd
