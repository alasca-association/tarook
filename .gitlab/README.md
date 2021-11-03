# How to generate a Changelog

Please also refer to [How to generate a changelog entry](https://docs.gitlab.com/ee/development/changelog.html#how-to-generate-a-changelog-entry)
and [Generate changelog data](https://docs.gitlab.com/ee/api/repositories.html#generate-changelog-data).

## Preliminaries

* [Generate a Gitlab token](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html) with API and repository access (read&write)

## Example

The helper script can be used to generate the changelog data.

```
$ TOKEN=ABCDEFGH12345 \
    BRANCH=my-awesome-feature-branch \ 
    VERSION=0.0.1 \ 
    FROM_SHA=5e3b57609773b78423de07969c32d730996192db \ 
    bash .gitlab/scripts/changelog.sh
```
