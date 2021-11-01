#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(dirname ${BASH_SOURCE[0]})"
REPO_ROOT_DIR="$(git rev-parse --show-toplevel)"

APICURIO_REGISTRY_URL="${APICURIO_REGISTRY_URL}"
BASIC_AUTH="${BASIC_AUTH}"
GROUP="${GROUP:-default}"
ASYNCAPI_DIR="${ASYNCAPI_DIR:-"${REPO_ROOT_DIR}/asyncapi"}"

function usage () {
    echo "$0: $1" >&2
    echo
    echo "Usage: $0 --apicurio-registry-url https://apicurio-registry.cloud [--basic-auth <API_KEY>:<API_KEY_SECRET>] [--group default] [--asyncapi-dir asyncapi/]"
    echo
    return 1
}

function register_asyncapis_apicurio () {
    for file in $(find "${ASYNCAPI_DIR}" -name "*.yaml" | sort); do
        register_asyncapi_file_apicurio "${file}"
    done
}

function register_asyncapi_file_apicurio () {
    local asyncapi_file="${1:?Requires AsyncAPI file as first parameter!}"
    local asyncapi_json="$(yq eval -j "${asyncapi_file}")"
    local default_artifactid="$(artifactid_from_path "${asyncapi_file}")"
    local artifactid="$(jq -r --arg defaultid "${default_artifactid}" '.id // $defaultid' <<<$asyncapi_json)"
    local generation="$(sed -n 's/^.*\.g\([0-9]\)\+\..*$/\1/p' <<<$asyncapi_basename)"
    local url="$(register_asyncapi_apicurio_url)"
    echo -e "\nRegister AsyncAPI ${asyncapi_file} at ${url}"
    curl $([ -n "${BASIC_AUTH}" ] && echo -u "${BASIC_AUTH}") \
        -X POST \
        -H "Content-type: application/json; artifactType=ASYNCAPI" \
        -H "X-Registry-ArtifactId: ${artifactid}" \
        -H "X-Registry-Version: ${generation}" \
        -d"${asyncapi_json}" \
        "${url}"
}

function artifactid_from_path () {
    local asyncapi_file="${1:?Requires AsyncAPI file as first parameter!}"
    local relative_path="$(realpath --relative-base "${ASYNCAPI_DIR}" "${asyncapi_file}")"
    local id_base="${relative_path%%.*}"
    local artifactid="urn:${id_base//\//.}"
    echo "${artifactid}"
}

function generation_from_filename () {
    local asyncapi_file="${1:?Requires AsyncAPI file as first parameter!}"
    local asyncapi_basename="$(basename "${asyncapi_file}")"

}

function register_asyncapi_apicurio_url () {
    echo "${APICURIO_REGISTRY_URL}/apis/registry/v2/groups/${GROUP}/artifacts?ifExists=RETURN_OR_UPDATE&canonical=true"
}

function parseCmd () {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --apicurio-registry-url)
                shift
                case "$1" in
                    ""|--*)
                        usage "Requires Apicurio Registry Url"
                        return 1
                        ;;
                    *)
                        APICURIO_REGISTRY_URL="$1"
                        shift
                        ;;
                esac
                ;;
            --basic-auth)
                shift
                case "$1" in
                    ""|--*)
                        usage "Requires Basic Auth"
                        return 1
                        ;;
                    *)
                        BASIC_AUTH="$1"
                        shift
                        ;;
                esac
                ;;
            --group)
                shift
                case "$1" in
                    ""|--*)
                        usage "Requires Apicurio Group ID"
                        return 1
                        ;;
                    *)
                        GROUP="$1"
                        shift
                        ;;
                esac
                ;;
            --asyncapi-dir)
                shift
                case "$1" in
                    ""|--*)
                        usage "Requires AsyncAPI Directory"
                        return 1
                        ;;
                    *)
                        ASYNCAPI_DIR="$1"
                        shift
                        ;;
                esac
                ;;
            *)
                usage "Unknown option: $1"
                return $?
                ;;
        esac
    done
    
    if [ -z "${APICURIO_REGISTRY_URL}" ]; then
        usage "Requires Apicurio Registry Url"
        return 1
    fi
    
    if [ -z "${GROUP}" ]; then
        usage "Requires Apicurio Group ID"
        return 1
    fi

    if [ -z "${ASYNCAPI_DIR}" ]; then
        usage "Requires AsyncAPI Directory"
        return 1
    fi
    ASYNCAPI_DIR="$(realpath "${ASYNCAPI_DIR}")"
    if [ ! -d "${ASYNCAPI_DIR}" ]; then
        usage "AsyncAPI directory does not exist"
        return 1
    fi

    return 0
}

function main () {
    parseCmd "$@"
    local retval=$?
    if [ $retval != 0 ]; then
        exit $retval
    fi

    register_asyncapis_apicurio
}

if [ "${BASH_SOURCE[0]}" == "$0" ]; then
   main "$@"
fi