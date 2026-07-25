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
        if [ ! -e "${PATH_ARG}" ]; then
            echo "ERROR: Path not found: ${PATH_ARG}" >&2
            exit 1
        fi
        if [ ! -d "${PATH_ARG}" ]; then
            echo "ERROR: -Path must be a directory, got a file: ${PATH_ARG}" >&2
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

protect_log() {
    # Best-effort redaction (mirrors run-gates.ps1 Protect-LogText).
    sed -E \
        -e 's/(api[_-]?key|token|password|secret|authorization)[[:space:]]*[=:][[:space:]]*[^[:space:]]+/\1=***/Ig' \
        -e 's/Bearer[[:space:]]+[^[:space:]]+/Bearer ***/Ig' \
        -e 's/\bsk-[A-Za-z0-9]{10,}/sk-***/g' \
        -e 's/\bgh[pousr]_[A-Za-z0-9]{20,}/gh*_***/g'
}

emit_json() {
    local summary="$1"
    # Minimal JSON (no jq required). commands built from RESULTS.
    local cmds="["
    local first=1
    local r cmd status secs ec
    for r in "${RESULTS[@]+"${RESULTS[@]}"}"; do
        [ -z "${r}" ] && continue
        IFS='|' read -r cmd status secs ec <<< "${r}"
        if [ "${first}" -eq 0 ]; then cmds="${cmds},"; fi
        first=0
        if [ -z "${ec}" ] || [ "${ec}" = "null" ]; then
            cmds="${cmds}{\"cmd\":\"${cmd}\",\"status\":\"${status}\",\"seconds\":${secs},\"exit\":null}"
        else
            cmds="${cmds}{\"cmd\":\"${cmd}\",\"status\":\"${status}\",\"seconds\":${secs},\"exit\":${ec}}"
        fi
    done
    cmds="${cmds}]"
    printf '{"repo":"%s","when":"%s","commands":%s,"summary":"%s"}\n' \
        "${REPO}" "${WHEN}" "${cmds}" "${summary}"
}

REPO="$(resolve_repo)"
WHEN="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
GATES=()
RESULTS=()
LOGS=()

if [ -f "${REPO}/scripts/gates.sh" ]; then
    GATES=("bash scripts/gates.sh")
elif [ -f "${REPO}/scripts/gates.ps1" ]; then
    echo "scripts/gates.ps1 requires powershell" >&2
    exit 2
else
    if [ -f "${REPO}/package.json" ]; then
        for n in lint typecheck test; do
            if grep -qE "\"scripts\"[^{]*\{[^}]*\"${n}\"" "${REPO}/package.json" 2>/dev/null \
                || grep -q "\"${n}\"" "${REPO}/package.json" 2>/dev/null; then
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
    if [ "${JSON}" -eq 1 ]; then
        RESULTS=()
        emit_json "NO_GATES"
    fi
    exit 4
fi

if [ "${DRY_RUN}" -eq 1 ]; then
    echo "## Gate results (DryRun)"
    echo "- env: $(uname -s) | repo: ${REPO} | when: ${WHEN}"
    echo "- ran:"
    for g in "${GATES[@]}"; do
        echo "  - \`${g}\` -> (dry-run)"
        RESULTS+=("${g}|DRY_RUN|0|null")
    done
    echo "- summary: DRY-RUN (${#GATES[@]} planned)"
    if [ "${JSON}" -eq 1 ]; then
        emit_json "DRY_RUN"
    fi
    exit 0
fi

ANY_FAIL=0
ANY_MISSING=0

run_gate() {
    local display="$1"
    shift
    local start end secs exit_code logfile pid elapsed
    start=$(date +%s)
    logfile="$(mktemp "${TMPDIR:-/tmp}/rg.XXXXXX")"

    (
        cd "${REPO}" || exit 127
        "$@" >"${logfile}" 2>&1
    ) &
    pid=$!
    elapsed=0
    while kill -0 "${pid}" 2>/dev/null; do
        if [ "${elapsed}" -ge "${TIMEOUT_SEC}" ]; then
            kill "${pid}" 2>/dev/null || true
            wait "${pid}" 2>/dev/null || true
            end=$(date +%s)
            secs=$((end - start))
            ANY_FAIL=1
            RESULTS+=("${display}|FAIL|${secs}|1")
            LOGS+=("TIMEOUT after ${TIMEOUT_SEC}s")
            rm -f "${logfile}"
            return
        fi
        sleep 1
        elapsed=$((elapsed + 1))
    done

    wait "${pid}"
    exit_code=$?
    end=$(date +%s)
    secs=$((end - start))
    local log
    log="$(cat "${logfile}" 2>/dev/null || true)"
    rm -f "${logfile}"

    if [ "${exit_code}" -eq 127 ]; then
        ANY_MISSING=1
        RESULTS+=("${display}|MISSING_RUNTIME|${secs}|2")
        LOGS+=("${log}")
    elif [ "${exit_code}" -ne 0 ]; then
        ANY_FAIL=1
        RESULTS+=("${display}|FAIL|${secs}|${exit_code}")
        LOGS+=("${log}")
    else
        RESULTS+=("${display}|PASS|${secs}|0")
        LOGS+=("")
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
elif [ "${ANY_FAIL}" -eq 1 ]; then
    echo "- summary: FAIL (${#RESULTS[@]} ran)"
else
    echo "- summary: PASS (${#RESULTS[@]} ran)"
fi

idx=0
for r in "${RESULTS[@]}"; do
    IFS='|' read -r cmd status secs ec <<< "${r}"
    if [ "${status}" = "FAIL" ] || [ "${status}" = "MISSING_RUNTIME" ]; then
        echo ""
        echo "### Log tail: ${cmd}"
        printf '%s\n' "${LOGS[$idx]}" | protect_log | tail -n 30
    fi
    idx=$((idx + 1))
done

if [ "${JSON}" -eq 1 ]; then
    if [ "${ANY_MISSING}" -eq 1 ]; then emit_json "MISSING_RUNTIME"
    elif [ "${ANY_FAIL}" -eq 1 ]; then emit_json "FAIL"
    else emit_json "PASS"
    fi
fi

if [ "${ANY_MISSING}" -eq 1 ]; then exit 2; fi
if [ "${ANY_FAIL}" -eq 1 ]; then exit 1; fi
exit 0

