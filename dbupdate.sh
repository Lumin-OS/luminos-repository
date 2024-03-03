
echo "###########################"
echo "Building the repo database."
echo "###########################"

## Arch: x86_64
cd x86_64
rm -f luminos-repository*

echo "###################################"
echo "Building for architecture 'x86_64'."
echo "###################################"

## repo-add
## -s: signs the packages
## -n: only add new packages not already in database
## -R: remove old package files when updating their entry
repo-add -s -n -R luminos-repository.db.tar.gz *.pkg.tar.zst

# Removing the symlinks because GitLab can't handle them.
rm luminos-repository.db
rm luminos-repository.db.sig
rm luminos-repository.files
rm luminos-repository.files.sig

# Renaming the tar.gz files without the extension.
mv luminos-repository.db.tar.gz luminos-repository.db
mv luminos-repository.db.tar.gz.sig luminos-repository-db.sig
mv luminos-repository.files.tar.gz luminos-repository.files
mv luminos-repository.files.tar.gz.sig luminos-repository.files.sig

echo "#######################################"
echo "Packages in the repo have been updated!"
echo "#######################################"
