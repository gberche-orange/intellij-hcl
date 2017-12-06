#!/usr/bin/env bash

# eg "terraform-provider-openstack"
PROVIDER=$1
# eg ~/go/src/terraform-provider-openstack
PROVIDER_REPO_PATH=$2
# E.g. https://github.com/terraform-providers/terraform-provider-openstack.git
PROVIDER_URL=$3
#USage
CUR="$(pwd)"

out="$CUR/schemas"
mkdir -p "$out"
rm -f "$CUR/failure.txt"

pushd "$GOPATH/src/github.com/terraform-providers" >/dev/null

mkdir -p "$GOPATH/src/github.com/terraform-providers"

#p=${PROVIDER}
#  if [ -d "$p" ]; then
#    echo "Updating $p"
#    pushd "$p" >/dev/null
#    [[ -d 'vendor' ]] && git checkout -- vendor/ >/dev/null
#    git pull >/dev/null &
#    popd >/dev/null
#  else
#    echo "Cloning $p"
#    git clone "${PROVIDER_URL}" >/dev/null &
#  fi

echo
echo "========================================"
echo "Waiting for update processes to finish"
wait
echo "All providers updated"
echo

generate_one() {
  go run generate-schema/generate-schema.go
  if [[ $? -ne 0 ]]; then
     echo "$1" >> "$2/failure.txt"
  fi
  echo "Finished $1"
}

for p in ${PROVIDER}; do
  pushd "$p" >/dev/null

  echo "Preparing $p"
  revision="$(git describe)"

  rm -rf generate-schema
  mkdir generate-schema
  cp -r "$CUR/template/generate-schema.go" generate-schema/generate-schema.go
  find generate-schema -type f -exec sed -i "s/__FULL_NAME__/$p/g" {} +
  find generate-schema -type f -exec sed -i "s/__NAME__/${p:19}/g" {} +
  find generate-schema -type f -exec sed -i "s/__REVISION__/$revision/g" {} +
  find generate-schema -type f -exec sed -i "s~__OUT__~$out~g" {} +

  #echo "Building $p"
  #make

  echo "Generating schema for $p"
  if [[ "$KILL_CPU" == "1" ]]; then
  (
    generate_one "$p" "$CUR"
  )&
  else
    echo generate_one "$p" "$CUR"
    generate_one "$p" "$CUR"
  fi

  popd >/dev/null
done

if [[ "$KILL_CPU" == "1" ]]; then
echo
echo "========================================"
echo "Waiting for 'generate-schemas' processes to finish"
wait
echo
fi

echo "========================================"
echo "Everything done!"
echo

popd >/dev/null

