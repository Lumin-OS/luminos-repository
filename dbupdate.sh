#!/usr/bin/env bash
# Sign packages individually before recording them in a signed repository DB.
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/x86_64"
key=547F4761802A0904A0B10E5FAE527343BC3E39B3
shopt -s nullglob
packages=(*.pkg.tar.zst)
(( ${#packages[@]} > 0 )) || { echo 'No packages to publish' >&2; exit 1; }

# Keep the current DB available if signing fails or pinentry is cancelled.
for package in "${packages[@]}"; do
    if [[ ! -f $package.sig ]] || ! gpg --batch --assert-signer "$key" --verify "$package.sig" "$package"; then
        signature=$(mktemp "$package.sig.XXXXXX")
        if gpg --yes --local-user "$key" --output "$signature" --detach-sign "$package"; then
            mv -- "$signature" "$package.sig"
        else
            rm -f -- "$signature"
            exit 1
        fi
    fi
done

# Build separately: publish DB aliases only after every archive is signed
# and repo-add has completed. Do not remove archives from the live repository.
staging=$(mktemp -d .dbupdate.XXXXXX)
trap 'rm -rf -- "$staging"' EXIT
for package in "${packages[@]}"; do
    ln -s -- "$PWD/$package" "$staging/$package"
    ln -s -- "$PWD/$package.sig" "$staging/$package.sig"
done
(cd -- "$staging" && repo-add -p -s -k "$key" luminos-repository.db.tar.gz ./*.pkg.tar.zst)
for name in db files; do
    mv -- "$staging/luminos-repository.$name.tar.gz" "luminos-repository.$name"
    mv -- "$staging/luminos-repository.$name.tar.gz.sig" "luminos-repository.$name.sig"
done
# Add publication files explicitly; do not sweep unrelated local files into Git.
git add -- "${packages[@]}" "${packages[@]/%/.sig}" \
    luminos-repository.db luminos-repository.db.sig \
    luminos-repository.files luminos-repository.files.sig
git commit -m "Publish signed packages and repository database"
git push origin HEAD
