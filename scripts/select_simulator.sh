#!/bin/bash

# Ordered by preference for pre-push and local test scripts.
PREFERRED_IOS_SIMULATORS=(
    "iPhone 17 Pro"
    "iPhone 17"
    "iPhone 16e"
    "iPhone 16"
)

extract_ios_simulator_names() {
    local device_list="$1"

    awk '
        /^-- / {
            in_ios = ($0 ~ /^-- iOS /)
            next
        }
        !in_ios { next }
        /^[[:space:]]+/ {
            line = $0
            if (line !~ /\([0-9A-Fa-f-]{36}\)[[:space:]]+\([^)]+\)$/) {
                next
            }
            sub(/^[[:space:]]+/, "", line)
            sub(/ \([0-9A-Fa-f-]{36}\)[[:space:]]+\([^)]+\)$/, "", line)
            print line
        }
    ' <<<"$device_list"
}

select_simulator_name_from_list() {
    local device_list="$1"
    local available_names
    available_names="$(extract_ios_simulator_names "$device_list")"

    if [[ -z "$available_names" ]]; then
        return 1
    fi

    local preferred_name
    for preferred_name in "${PREFERRED_IOS_SIMULATORS[@]}"; do
        if printf '%s\n' "$available_names" | grep -Fxq "$preferred_name"; then
            printf '%s\n' "$preferred_name"
            return 0
        fi
    done

    printf '%s\n' "$available_names" | sed -n '1p'
}

select_simulator_name() {
    local device_list
    device_list="$(xcrun simctl list devices available 2>/dev/null || true)"
    select_simulator_name_from_list "$device_list"
}

select_simulator_destination_from_list() {
    local device_list="$1"
    local simulator_name
    simulator_name="$(select_simulator_name_from_list "$device_list")" || return 1
    printf 'platform=iOS Simulator,name=%s\n' "$simulator_name"
}

select_simulator_destination() {
    local simulator_name
    simulator_name="$(select_simulator_name)" || return 1
    printf 'platform=iOS Simulator,name=%s\n' "$simulator_name"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    case "${1:-}" in
        --name)
            select_simulator_name
            ;;
        --destination)
            select_simulator_destination
            ;;
        *)
            echo "Usage: $0 [--name|--destination]" >&2
            exit 2
            ;;
    esac
fi
