#!/bin/sh

# Create the first PR
git checkout -b enable-witness main
cp ./pr-1/pipeline.yml ./.github/workflows/pipeline.yml
git add ./.github/workflows/pipeline.yml
git commit -m "Enable witness"
git push origin enable-witness
gh pr create --base main --head enable-witness --fill

# Create the second PR
git checkout -b reduce-cves main
cp ./pr-2/Dockerfile ./Dockerfile
git add ./Dockerfile
git commit -m "Reduce CVEs"
git push origin reduce-cves
gh pr create --base main --head reduce-cves --fill

