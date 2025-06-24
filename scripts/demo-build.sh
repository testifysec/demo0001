#!/bin/bash

# Demo build script that simulates conda builds
# This is used for demos to avoid long build times

RECIPE=$1
if [ -z "$RECIPE" ]; then
    echo "Usage: $0 <recipe-path>"
    exit 1
fi

PACKAGE_NAME=$(grep "name:" $RECIPE/meta.yaml | head -1 | awk '{print $2}')
PACKAGE_VERSION=$(grep "version:" $RECIPE/meta.yaml | head -1 | awk '{print $2}' | tr -d '"')

echo "Building $PACKAGE_NAME $PACKAGE_VERSION..."
echo ""

# Simulate build steps
echo "[ 1/7] Downloading source..."
sleep 1
echo "[ 2/7] Extracting source..."
sleep 1
echo "[ 3/7] Configuring build environment..."
sleep 1
echo "[ 4/7] Running build script..."
sleep 2
echo "[ 5/7] Installing files..."
sleep 1
echo "[ 6/7] Creating package..."
sleep 1
echo "[ 7/7] Running tests..."
sleep 1

# Create a dummy package file
mkdir -p ~/miniconda/conda-bld/osx-arm64
PACKAGE_FILE="$HOME/miniconda/conda-bld/osx-arm64/${PACKAGE_NAME}-${PACKAGE_VERSION}-py313h0_0.tar.bz2"
echo "Demo package for $PACKAGE_NAME" > /tmp/demo-content.txt
tar -cjf "$PACKAGE_FILE" -C /tmp demo-content.txt
rm /tmp/demo-content.txt

echo ""
echo "Successfully built $PACKAGE_FILE"
echo ""
echo "Package details:"
echo "  Name: $PACKAGE_NAME"
echo "  Version: $PACKAGE_VERSION"
echo "  Size: $(ls -lh $PACKAGE_FILE | awk '{print $5}')"
echo "  SHA256: $(shasum -a 256 $PACKAGE_FILE | awk '{print $1}')"