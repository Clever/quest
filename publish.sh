#!/bin/bash
version=`cat package.json | grep version | sed -ne 's/^[ ]*"version":[ ]*"\([0-9\.]*\)",$/\1/p'`
read -p "Publish and tag as v$version? " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    npm publish
    git tag -a v$version -m "version $version"
    git push --tags
fi
