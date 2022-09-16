#!/usr/bin/env bash
set -euo pipefail
namespaces=()
resources=()
outpath="$1"
shift

all_namespaces=0
while [ "$#" -gt 0 ]; do
    arg="$1"
    shift
    if [ -z "$arg" ]; then
        break
    fi
    if [ "$arg" = '--all-namespaces' ]; then
        all_namespaces=1
        continue
    fi
    namespaces+=("$arg")
done

for arg; do
    resources+=("$arg")
done

if [ "$all_namespaces" == '1' ]; then
    namespaces=()
    while IFS= read -r name; do
        namespaces+=("$name")
    done < <(kubectl get namespace -o jsonpath='{ range .items[*] }{ .metadata.name }{ "\n" }{ end }')
fi

logfile="$outpath/_dump.log"
mkdir -p "$(dirname "$logfile")"

function tracerun() {
    cmd="$1"
    shift
    printf '+ %q' "$cmd" >&2
    for arg; do
        printf ' %q' "$arg" >&2
    done
    printf '\n' >&2
    set +e
    "$cmd" "$@"
    exitcode="$?"
    set -e
    printf '%q -> %d\n' "$cmd" "$exitcode" >&2
    return $exitcode
}

function dump_resource() {
    basedir="$1"
    namespace="$2"
    resource="$3"

    if [ -f "$basedir/-/$resource.json" ]; then
        # resource type is namespaceless and has already been dumped. skip.
        return 0
    fi

    json_tmp="$(mktemp -p "$basedir")"
    if ! tracerun kubectl -n "$namespace" get "$resource" -o json >"$json_tmp" 2>>"$logfile"; then
        printf 'error: failed to dump %q/%q. see %s for details\n' "$namespace" "$resource" "$logfile" >&2
        rm -f "$json_tmp"
        return 1
    fi

    if [ "$(jq -r '.items | all(.metadata.namespace)' "$json_tmp")" == 'false' ]; then
        # unnamespaced
        namespace='-'
    fi

    if [ "$resource" == 'pod' ] || [ "$resource" == 'pods' ]; then
        dump_logs=1
    else
        dump_logs=0
    fi

    outdir="$basedir/$namespace/$resource/"
    mkdir -p "$outdir"
    while IFS='' read -r item; do
        name="$(jq -r '.metadata.name' <<<"$item")"
        outfile="$outdir/$name.json"
        jq '.' <<<"$item" > "$outfile"
        if [ "$dump_logs" == '1' ]; then
            logdir="$outdir/$name"
            mkdir -p "$logdir"
            while IFS='' read -r container_name; do
                tracerun kubectl logs -n "$namespace" "$name" -c "$container_name" 2>>"$logfile" | gzip --fast > "$logdir/$container_name-current.log.gz" || true
                tracerun kubectl logs -n "$namespace" -p "$name" -c "$container_name" 2>>"$logfile" | gzip --fast > "$logdir/$container_name-previous.log.gz" || true
            done < <(jq -r '.spec.containers[].name' "$outfile")
        fi
    done < <(jq -c '.items[]' < "$json_tmp")
    rm -f "$json_tmp"
}

IFS=$'\n'
for ns in "${namespaces[@]}"; do
    ns_dir="$outpath/$ns"
    mkdir -p "$ns_dir"
    kubectl -n "$ns" get event -o wide > "$ns_dir/event.txt"
    for flagged_resource in "${resources[@]}"; do
        resource="${flagged_resource#+}"
        printf '%q/%q ...\n' "$ns" "$resource"
        dump_resource "$outpath" "$ns" "$resource" || true
    done
done
