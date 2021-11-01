#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(dirname ${BASH_SOURCE[0]})"
REPO_ROOT_DIR="$(git rev-parse --show-toplevel)"

ASYNCAPI_DIRECTORY_URL="${ASYNCAPI_DIRECTORY_URL}"
BASIC_AUTH="${BASIC_AUTH}"
ASYNCAPI_DIR="${ASYNCAPI_DIR:-"${REPO_ROOT_DIR}/asyncapi"}"

function usage () {
    echo "$0: $1" >&2
    echo
    echo "Usage: $0 --asyncapi-directory-url https://asyncapi-directory.cloud [--basic-auth <API_KEY>:<API_KEY_SECRET>] [--asyncapi-dir asyncapi/]"
    echo
    return 1
}

function register_asyncapis_directory () {
    for file in $(find "${ASYNCAPI_DIR}" -name "*.yaml" | sort); do
        register_asyncapi_file_directory "${file}"
    done
}

function register_asyncapi_file_directory () {
    local asyncapi_file="${1:?Requires AsyncAPI file as first parameter!}"
    local asyncapi_json="$(yq eval -j "${asyncapi_file}")"
    local default_artifactid="$(artifactid_from_path "${asyncapi_file}")"
    local artifactid="$(jq -r --arg defaultid "${default_artifactid}" '.id // $defaultid' <<<$asyncapi_json)"
    local generation="$(generation_from_filename "${asyncapi_file}")"
    local directory_asyncapi_json="$(echo "{}" | jq -c --arg artifactid "${artifactid}" --argjson definition "${asyncapi_json}" '{artifactId:$artifactid, definition:$definition}')"
    if [[ "$(check_asyncapi_registered "${artifactid}" "${generation}")" =~ ^2 ]]; then
        echo -e "\nCould not register AsyncAPI ${asyncapi_file} at ${ASYNCAPI_DIRECTORY_URL}. AsyncAPI id ${artifactid} with generation ${generation} already exists."
    else
        echo -e "\nRegister AsyncAPI ${asyncapi_file} at ${ASYNCAPI_DIRECTORY_URL}"
        curl -f $([ -n "${BASIC_AUTH}" ] && echo -u "${BASIC_AUTH}") \
            -X POST \
            -H "Content-type: application/json" \
            -d"${directory_asyncapi_json}" \
            "${ASYNCAPI_DIRECTORY_URL}/api/asyncapi"
    fi
}

function artifactid_from_path () {
    local asyncapi_file="${1:?Requires AsyncAPI file as first parameter!}"
    local relative_path="$(realpath --relative-base "${ASYNCAPI_DIR}" "${asyncapi_file}")"
    local id_base="${relative_path%%.*}"
    local artifactid="urn:${id_base//\//:}"
    echo "${artifactid}"
}

function generation_from_filename () {
    local asyncapi_file="${1:?Requires AsyncAPI file as first parameter!}"
    local asyncapi_basename="$(basename "${asyncapi_file}")"
    local generation="$(sed -n 's/^.*\.g\([0-9]\)\+\..*$/\1/p' <<<$asyncapi_basename)"
    echo "${generation}"
}

function check_asyncapi_registered () {
    local artifactid="${1:?Requires artifact id as first parameter!}"
    local generation="${2:?Requires generation as second parameter!}"
    local statuscode="$(curl -s -o /dev/null -w "%{http_code}" ${ASYNCAPI_DIRECTORY_URL}/api/asyncapi/${artifactid}/${generation})"
    echo "${statuscode}"
}

function parseCmd () {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --asyncapi-directory-url)
                shift
                case "$1" in
                    ""|--*)
                        usage "Requires AsyncAPI Directory Url"
                        return 1
                        ;;
                    *)
                        ASYNCAPI_DIRECTORY_URL="$1"
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
    
    if [ -z "${ASYNCAPI_DIRECTORY_URL}" ]; then
        usage "Requires AsyncAPI Directory Url"
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

    register_asyncapis_directory
}

if [ "${BASH_SOURCE[0]}" == "$0" ]; then
   main "$@"
fi