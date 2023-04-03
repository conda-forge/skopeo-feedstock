#! /usr/bin/env bash

set -x

cp ./src/LICENSE ./
module_path="${GOPATH:-"$( go env GOPATH )"}"/src/github.com/containers/skopeo
mkdir -p "$( dirname "${module_path}" )"
mv ./src "${module_path}"

export GO111MODULE=on

disable_cgo=0
if ! [[ ${target_platform} =~ linux.* ]] ; then
    disable_cgo=1
fi

export GOARCH="amd64"
export GOOS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
case $ARCH in
    amd64 | x86_64)
        export GOARCH="amd64"
        make -C "${module_path}" install \
            DISABLE_CGO="${disable_cgo}" \
            CONTAINERSCONFDIR="${PREFIX}/share/containers" \
            LOOKASIDEDIR="${PREFIX}/etc/containers/sigstore" \
            GIT_COMMIT=
        ;;
    arm64 | aarch64)
        export GOARCH="arm64"
        pushd "${module_path}"
        make bin/skopeo.${GOOS}.${GOARCH} \
            DISABLE_CGO="${disable_cgo}" \
            CONTAINERSCONFDIR="${PREFIX}/share/containers" \
            LOOKASIDEDIR="${PREFIX}/etc/containers/sigstore" \
            GIT_COMMIT=
        install -d -m 755 ${DESTDIR}${BINDIR}
        install -m 755 bin/skopeo.${GOOS}.${GOARCH} ${DESTDIR}${BINDIR}/skopeo
        make install-docs install-completions \
            DISABLE_CGO="${disable_cgo}" \
            CONTAINERSCONFDIR="${PREFIX}/share/containers" \
            LOOKASIDEDIR="${PREFIX}/etc/containers/sigstore" \
            GIT_COMMIT=
        popd
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

export THIRD_PARTY_LICENSES="${PWD}/3rd_party_licenses/"
pushd "${module_path}"
echo "replace github.com/containers/common v0.51.0 => github.com/containers/common v1.0.1" >> go.mod
go mod tidy -compat=1.17
go mod vendor
go-licenses save ./cmd/skopeo --save_path="${THIRD_PARTY_LICENSES}"
popd
