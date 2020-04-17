#!/bin/bash
set -euo pipefail

if [ "$#" != '4' ]; then
  printf 'usage: %s DIR NFILES MEGS INTERVAL\n\n' "$0" >&2
  printf 'Check correctness of the storage stack.\n\n' >&2
  printf 'positional arguments:\n' >&2
  printf '  DIR       Path to output directory (must not exist)\n' >&2
  printf '  NFILES    Half of the total number of files to create\n' >&2
  printf '  MEGS      Size of each file in MiB\n' >&2
  printf '  INTERVAL  sleep(1) time between a single rewrite/check iteration\n' >&2
  printf '\n\n' >&2
  printf 'This tool creates two directories under DIR: stable and rewritten.\n' >&2
  printf 'In each directory, NFILES files of MEGS MiB size will be created. The\n' >&2
  printf 'files in the stable subdirectory are only written once at start up,\n' >&2
  printf 'while the files in the rewritten subdirectory are created once per\n' >&2
  printf 'iteration.\n\n' >&2
  printf 'After writing the files, the tool calculates the SHA256SUMS file for\n' >&2
  printf 'each subdirectory using sha256sum(1). On each iteration, the SHA256SUMS\n' >&2
  printf 'are checked against the files as they exist on the disk.\n\n' >&2
  printf 'The idea of this tool is to detect silent corruption of data on the\n' >&2
  printf 'storage, for example during upgrade operations which touch the ceph\n' >&2
  printf 'cluster.\n\n' >&2
  printf 'For representative results, NFILES*MEGS MiB should be chosen larger than\n' >&2
  printf 'than the amount of RAM available on the worker node.\n' >&2
  exit 2
fi

dir="$1"
shift
nfiles="$1"
shift
nmegsperfile="$1"
shift
interval="$1"
shift

if [ -e "$dir" ]; then
  echo "$dir must not exist" >&2
  exit 1
fi

if [ ! -e "/cheaprandom.py" ]; then
  echo "/cheaprandom.py must exist" >&2
  echo >&2
  echo "You have to install the cheaprandom.py tool in /, also make sure that python3 is installed." >&2
  exit 3
fi

if ! which python3 >/dev/null 2>/dev/null; then
  echo "unable to find python3 in PATH" >&2
  exit 3
fi

mkdir -p "$dir/stable" "$dir/rewritten"

pushd "$dir"

function log() {
  printf "%s INFO: %s\n" "$(date --iso-8601=seconds)" "$1"
}

function report_error() {
  msg="$1"
  printf "%s ERROR: %s\n" "$(date --iso-8601=seconds)" "$msg" >&2
}

function checkdata() {
  subdir="$1"
  output="$(sha256sum -c "$subdir.sha256sum")"
  if echo "$output" | grep -v OK ; then
    report_error "CHECK FAILED: $(echo "$output" | tr '\n' '\t')"
  fi
}

function gendata() {
  subdir="$1"
  # prepare stable data
  for i in $(seq -f '%04.0f' 1 "$nfiles"); do
    python3 /cheaprandom.py "$nmegsperfile" "$subdir/$i" || report_error "WRITE FAILED: $subdir/$i"
  done
  sha256sum "$subdir"/* > "$subdir.sha256sum"
  sync || report_error "SYNC FAILED"
  checkdata "$subdir"
}

log "generating stable data ..."
gendata stable
log "stable data generated"

while true; do
  log "re-writing volatile data"
  gendata rewritten
  log "checking stable data"
  checkdata stable
  sleep "$interval"
done
