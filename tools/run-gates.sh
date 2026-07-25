#!/usr/bin/env bash
# Bash 3.2+ wrapper for tools/run-gates.ps1
# Delegates to PowerShell when available; else minimal Bash discovery.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PS1_SCRIPT="${SCRIPT_DIR}/run-gates.ps1"

find_powershell() {
    if command -v pwsh >/dev/null 2>&1; then
        command -v pwsh
        return 0
    fi
    if command -v powershell.exe >/dev/null 2>&1; then
        command -v powershell.exe
        return 0
    fi
    if [ -x "/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe" ]; then
        echo "/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"
        return 0
    fi
    return 1
}

# Prefer delegating to the .ps1 implementation (same exit codes / output).
PS_EXE="$(find_powershell || true)"
if [ -n "${PS_EXE}" ] && [ -f "${PS1_SCRIPT}" ]; then
    exec "${PS_EXE}" -NoProfile -ExecutionPolicy Bypass -File "${PS1_SCRIPT}" "$@"
fi

# --- Minimal Bash fallback (no powershell) ---

TIMEOUT_SEC=900
PATH_ARG=""
JSON=0
DRY_RUN=0

while [ $# -gt 0 ]; do
    case "$1" in
        -Path) PATH_ARG="$2"; shift 2 ;;
        -Json) JSON=1; shift ;;
        -DryRun) DRY_RUN=1; shift ;;
        -TimeoutSec) TIMEOUT_SEC="$2"; shift 2 ;;
        *) echo "Unknown arg: $1" >&2; exit 1 ;;
    esac
done

resolve_repo() {
    if [ -n "${PATH_ARG}" ]; then
        if [ ! -d "${PATH_ARG}" ]; then
            echo "Path not found: ${PATH_ARG}" >&2
            exit 1
        fi
        cd "${PATH_ARG}" && pwd
        return
    fi
    local start="$(pwd)"
    local cur="${start}"
    while true; do
        if [ -d "${cur}/.git" ]; then
            echo "${cur}"
            return
        fi
        local parent="$(dirname "${cur}")"
        if [ "${parent}" = "${cur}" ]; then
            echo "${start}"
            return
        fi
        cur="${parent}"
    done
}

REPO="$(resolve_repo)"
WHEN="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
GATES=()

if [ -f "${REPO}/scripts/gates.sh" ]; then
    GATES=("bash scripts/gates.sh")
elif [ -f "${REPO}/scripts/gates.ps1" ]; then
    echo "scripts/gates.ps1 requires powershell" >&2
    exit 2
else
    if [ -f "${REPO}/package.json" ]; then
        for n in lint typecheck test; do
            if grep -q "\"${n}\"" "${REPO}/package.json" 2>/dev/null; then
                GATES+=("npm run ${n}")
            fi
        done
    fi
    if [ -f "${REPO}/Makefile" ]; then
        for t in lint test check; do
            if grep -qE "^[[:space:]]*${t}[[:space:]]*:" "${REPO}/Makefile" 2>/dev/null; then
                GATES+=("make ${t}")
            fi
        done
    fi
    if [ -f "${REPO}/scripts/check-layout.ps1" ]; then
        echo "check-layout.ps1 requires powershell" >&2
        exit 2
    fi
fi

if [ ${#GATES[@]} -eq 0 ]; then
    echo "## Gate results"
    echo "- env: $(uname -s) | repo: ${REPO} | when: ${WHEN}"
    echo "- ran: (none)"
    echo "- summary: NO GATES (exit 4)"
    exit 4
fi

if [ "${DRY_RUN}" -eq 1 ]; then
    echo "## Gate results (DryRun)"
    echo "- env: $(uname -s) | repo: ${REPO} | when: ${WHEN}"
    echo "- ran:"
    for g in "${GATES[@]}"; do
        echo "  - \`${g}\` -> (dry-run)"
    done
    echo "- summary: DRY-RUN (${#GATES[@]} planned)"
    exit 0
fi

ANY_FAIL=0
ANY_MISSING=0
RESULTS=()

run_gate() {
    local display="$1"
    shift
    local start end secs exit_code
    start=$(date +%s)
    local log
    log="$(cd "${REPO}" && "$@" 2>&1)" || true
    exit_code=$?
    end=$(date +%s)
    secs=$((end - start))
    if [ "${exit_code}" -eq 127 ]; then
        ANY_MISSING=1
        RESULTS+=("${display}|MISSING_RUNTIME|${secs}|2")
    elif [ "${exit_code}" -ne 0 ]; then
        ANY_FAIL=1
        RESULTS+=("${display}|FAIL|${secs}|${exit_code}")
    else
        RESULTS+=("${display}|PASS|${secs}|0")
    fi
}

for g in "${GATES[@]}"; do
    case "${g}" in
        "bash "*) run_gate "${g}" bash "${REPO}/scripts/gates.sh" ;;
        "npm run "*) run_gate "${g}" npm run "${g#npm run }" ;;
        "make "*) run_gate "${g}" make -C "${REPO}" "${g#make }" ;;
    esac
done

echo "## Gate results"
echo "- env: $(uname -s) | repo: ${REPO} | when: ${WHEN}"
echo "- ran:"
for r in "${RESULTS[@]}"; do
    IFS='|' read -r cmd status secs ec <<< "${r}"
    echo "  - \`${cmd}\` -> ${status} (${secs}s)"
done

if [ "${ANY_MISSING}" -eq 1 ]; then
    echo "- summary: MISSING_RUNTIME (${#RESULTS[@]} ran)"
    exit 2
elif [ "${ANY_FAIL}" -eq 1 ]; then
    echo "- summary: FAIL (${#RESULTS[@]} ran)"
    exit 1
fi
echo "- summary: PASS (${#RESULTS[@]} ran)"
exit 0
