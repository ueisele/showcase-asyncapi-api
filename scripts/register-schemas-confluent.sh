#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(dirname ${BASH_SOURCE[0]})"
REPO_ROOT_DIR="$(git rev-parse --show-toplevel)"

SCHEMA_REGISTRY_URL="${SCHEMA_REGISTRY_URL}"
BASIC_AUTH="${BASIC_AUTH}"
ASYNCAPI_DIR="${ASYNCAPI_DIR:-"${REPO_ROOT_DIR}/asyncapi"}"
SCHEMA_DIR="${SCHEMA_DIR:-"${REPO_ROOT_DIR}/schema"}"

function usage () {
    echo "$0: $1" >&2
    echo
    echo "Usage: $0 --schema-registry-url https://schema-registry.cloud [--basic-auth <API_KEY>:<API_KEY_SECRET>] [--asyncapi-dir asyncapi/] [--schema-dir schema/]"
    echo
    return 1
}

function register_schemas_confluent () {
    for file in $(find "${ASYNCAPI_DIR}" -name "*.yaml" | sort); do
        register_schemas_confluent_asyncapi_file "${file}"
    done
}

function register_schemas_confluent_asyncapi_file () {
    local asyncapi_file="${1:?Requires AsyncAPI file as first parameter!}"
    local asyncapi_json="$(yq eval -j "${asyncapi_file}")"
    _channels_topic_schema_map() {
        jq -c '.channels | to_entries[] | { topic: .key, schema: .value | to_entries[].value.message?.payload."$ref" | select(. != null)}' <<<$asyncapi_json
    }
    for channel in $(_channels_topic_schema_map); do
        local topic="$(jq -r '.topic' <<<$channel)" 
        local schema_file="$(jq -r '.schema' <<<$channel)"
        register_schema_confluent_topic "${topic}" "value" "${schema_file}"
    done    
}

function register_schema_confluent_topic () {
    local topic="${1:?Requires topic name as first parameter!}"
    local kind="${2:?Requires schema kind as second parameter!}"
    local schema_file="${3:?Requires schema file as third parameter!}"
    local schema_json=""
    if [[ "${schema_file}" =~ ^http(s)?:// ]]; then 
        schema_json="$(curl -Ls "${schema_file}" | jq -c .)"
    else
        schema_json="$(cat "${schema_file}" | jq -c .)"
    fi
    local confluent_schema_json="$(echo "{}" | jq -c --arg schema "${schema_json}" '{schema:$schema}')"
    local url="$(register_schema_confluent_url "${topic}" "${kind}")"
    echo -e "\nRegister schema ${schema_file} at ${url}"
    curl -f $([ -n "${BASIC_AUTH}" ] && echo -u "${BASIC_AUTH}") \
        -X POST \
        -H "Content-Type: application/vnd.schemaregistry.v1+json" \
        -d"${confluent_schema_json}" \
        "${url}"
}

function register_schema_confluent_url () {
    local topic="${1:?Requires topic name as first parameter!}"
    local kind="${2:?Requires schema kind as second parameter!}"
    echo "${SCHEMA_REGISTRY_URL}/subjects/${topic}-${kind}/versions"
}

function parseCmd () {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --schema-registry-url)
                shift
                case "$1" in
                    ""|--*)
                        usage "Requires Schema Registry Url"
                        return 1
                        ;;
                    *)
                        SCHEMA_REGISTRY_URL="$1"
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
            --schema-dir)
                shift
                case "$1" in
                    ""|--*)
                        usage "Requires Schemas Directory"
                        return 1
                        ;;
                    *)
                        SCHEMA_DIR="$1"
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
    
    if [ -z "${SCHEMA_REGISTRY_URL}" ]; then
        usage "Requires Schema Registry Url"
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

    if [ -z "${SCHEMA_DIR}" ]; then
        usage "Requires Schema Directory"
        return 1
    fi
    SCHEMA_DIR="$(realpath "${SCHEMA_DIR}")"
    if [ ! -d "${SCHEMA_DIR}" ]; then
        usage "Schema directory does not exist"
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

    register_schemas_confluent
}

if [ "${BASH_SOURCE[0]}" == "$0" ]; then
   main "$@"
fi