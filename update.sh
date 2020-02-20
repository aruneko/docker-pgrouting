#!/bin/bash
# Derived from https://github.com/docker-library/postgres/blob/master/update.sh
set -Eeuo pipefail

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
	versions=( */Dockerfile )
fi
versions=( "${versions[@]%/Dockerfile}" )

# sort version numbers with highest last (so it goes first in .travis.yml)
IFS=$'\n'; versions=( $(echo "${versions[*]}" | sort -V) ); unset IFS

defaultDebianSuite='buster-slim'
declare -A debianSuite=(
    # https://github.com/docker-library/postgres/issues/582
    [9.5]='stretch-slim'
    [9.6]='stretch-slim'
    [10]='stretch-slim'
    [11]='stretch-slim'
)
defaultAlpineVersion='3.11'
declare -A alpineVersion=(
    #[9.6]='3.5'
)

defaultPostgisDebPkgNameVersionSuffix='3'
declare -A postgisDebPkgNameVersionSuffixes=(
    [2.5]='2.5'
    [3.0]='3'
)

declare -A suitePackageList=() suiteArches=()
for version in "${versions[@]}"; do
    IFS=- read postgresVersion postgisVersion pgroutingVersion <<< "$version"

    postgisDockerTagVersion="${postgresVersion}-${postgisVersion}"

    srcVersion="${pgroutingVersion}"
    srcSha256="$(curl -sSL "https://github.com/pgRouting/pgrouting/archive/v${srcVersion}.tar.gz" | sha256sum | awk '{ print $1 }')"
    (
        set -x
        cp -p Dockerfile.template "$version/"
        mv "$version/Dockerfile.template" "$version/Dockerfile"
        sed -i 's/%%POSTGIS_DOCKER_TAG_VERSION%%/'"$postgisDockerTagVersion"'/g; s/%%PGROUTING_VERSION%%/'"$pgroutingVersion"'/g; s/%%PGROUTING_SHA256%%/'"$srcSha256"'/g;' "$version/Dockerfile"
        
    )
done

