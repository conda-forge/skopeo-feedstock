#! /usr/bin/env bash

set -x

cp ./src/LICENSE ./
module_path="${GOPATH:-"$( go env GOPATH )"}"/src/github.com/containers/skopeo
mkdir -p "$( dirname "${module_path}" )"
mv ./src "${module_path}"

export GO111MODULE=auto

pushd "$module_path"
go mod download
go-licenses save ./cmd/skopeo --save_path=3rd_party_license
popd

export GOARCH="amd64"
export GOOS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
case $ARCH in
    amd64 | x86_64)
        export GOARCH="amd64"
        ;;
    arm64 | aarch64)
        export GOARCH="arm64"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

disable_cgo=0
if ! [[ ${target_platform} =~ linux.* ]] ; then
    disable_cgo=1
fi
make -C "${module_path}" install \
  DISABLE_CGO="${disable_cgo}" \
  CONTAINERSCONFDIR="${PREFIX}/share/containers" \
  LOOKASIDEDIR="${PREFIX}/etc/containers/sigstore" \
  GIT_COMMIT=


gather_licenses() {
  # shellcheck disable=SC2039  # Allow widely supported non-POSIX local keyword.
  local module output tmp_dir acc_dir
  output="${1}"
  shift
  tmp_dir="$(pwd)/gather-licenses-tmp"
  acc_dir="$(pwd)/gather-licenses-acc"
  mkdir "${acc_dir}"
  cat > "${output}" <<'EOF'
--------------------------------------------------------------------------------
The output below is generated with `go-licenses csv` and `go-licenses save`.
================================================================================
EOF
  for module ; do
    cat >> "${output}" <<EOF

go-licenses csv ${module}
================================================================================
EOF
    go-licenses csv "${module}" | sort >> "${output}"
    go-licenses save "${module}" --save_path="${tmp_dir}"
    chmod -R +w "${acc_dir}" "${tmp_dir}"
    cp -r "${tmp_dir}"/* "${acc_dir}"/
    rm -r "${tmp_dir}"
  done
  # shellcheck disable=SC2016  # Not expanding $ in single quotes intentional.
  find "${acc_dir}" -type f | sort | xargs -L1 sh -c '
cat <<EOF

--------------------------------------------------------------------------------
${2#${1%/}/}
================================================================================
EOF
cat "${2}"
' -- "${acc_dir}" >> "${output}"
  rm -r "${acc_dir}"
}
