#!/usr/bin/env bash

# Update the LCM defined gitignore rules in the cluster repository's gitignore
#
# The part to be updated is surrounded with markers like so:
#
#   ##### BEGIN managed by yk8s(<template-name>)
#   foo
#   bar/baz
#   ##### END managed by yk8s
#
# In case the markers are missing, they are added at the end of the file.
# If the end marker is followed by non-empty lines a warning is output
#  because in this case it is not guaranteed that all of the LCM's gitignore
#  rules are effective.
#
# The start marker can be annotated with the name of the cluster repo template
#  from which updates shall be sourced.
# If the annotation is missing or malformed the "minimal" template is used.

set -euo pipefail
actions_dir="$(dirname "$0")/.."

# shellcheck source=actions/lib.sh
. "$actions_dir/lib.sh"


start_marker="##### BEGIN managed by yk8s"
end_marker="##### END managed by yk8s"
filter_marker_annotation() {
  # Get start marker line and extract optional annotation
  # NOTE: Missing start marker and malformed annotations are ignored
  (grep --max-count=1 "^${start_marker}.*$" || true) \
  | sed "s/^${start_marker}\((\(.*\))\|.*\)$/\2/"
}

cluster_repo_gitignore="${cluster_repository}/.gitignore"

cluster_repo_template="$(filter_marker_annotation < "${cluster_repo_gitignore}")"
cluster_repo_template="${cluster_repo_template:-minimal}"
# Ensure annotated cluster repo template exists, fail otherwise
if ! [ -d "${cluster_repo_template_dir}/${cluster_repo_template:?}" ]; then
  errorf "Unknown cluster repo template name '${cluster_repo_template}' \
in start marker annotation in ${cluster_repo_gitignore}.
Must be one of: $(cluster_repo_template_list)"
  exit 1
fi
lcm_defined_gitignore="${code_repository}/templates/cluster-repo/${cluster_repo_template:?}/.gitignore"


# Ensure that start and end marker exist in order
case "$(grep -E "^(${start_marker}.*|${end_marker})$" "${cluster_repo_gitignore}")" in
  "${start_marker}"*$'\n'"${end_marker}")
    # pass
    ;;
  "${end_marker}"$'\n'"${start_marker}"*)
    errorf "\
Lines '${start_marker}' and '${end_marker}' are swapped in ${cluster_repo_gitignore}. \
Aborting..."
    exit 1
    ;;
  "${end_marker}")
    errorf "\
Line '${start_marker}' is missing in ${cluster_repo_gitignore}. \
Aborting..."
    exit 1
    ;;
  "${start_marker}"*)
    errorf "\
Line '${end_marker}' is missing in ${cluster_repo_gitignore}. \
Aborting..."
    exit 1
    ;;
  "")
    notef "\
Lines '${start_marker}' and '${end_marker}' are missing in ${cluster_repo_gitignore}. \
Adding them now..."
    printf "\n%s\n%s" "${start_marker}" "${end_marker}" >> "${cluster_repo_gitignore}"
    ;;
  *)
    errorf "\
Multiple lines of '${start_marker}' and or '${end_marker}' found in ${cluster_repo_gitignore}. \
Aborting..."
    exit 1
    ;;
esac

# Warn if end marker is followed by non-empty lines
# shellcheck disable=SC2016
if [ \
  "$(sed --quiet --expression="/^${end_marker}"'$/,${p}' "${cluster_repo_gitignore}")" \
  != "${end_marker}" \
]; then
  warningf "\
Line '${end_marker}' is followed by one or more non-empty lines.
The LCM's gitignore rules might not be effective."
fi

# In the cluster repo's gitignore file
# replace the lines between start and end marker
# with the lines of the LCM defined gitignore file
# plus adds a hint
# NOTE: See also https://www.gnu.org/software/sed/manual/html_node/sed-commands-list.html
sed \
  --in-place \
  --expression="
    /^${start_marker}.*$/,/^${end_marker}$/{
      /^${start_marker}.*$/{
        r ${lcm_defined_gitignore}
      };
      d
    }
  " \
  "${cluster_repo_gitignore}"

notef "Synced LCM defined gitignore rules to ${cluster_repo_gitignore}"

hintf "It is recommended to apply the gitignore rules to the git index \
by running:

git ls-files --ignored --cached --exclude-from=.gitignore -z \
| xargs --no-run-if-empty --null git rm --cached -r"

if ! git diff --quiet --exit-code -- .gitignore; then
  run git add .gitignore
fi
