#!/bin/bash
# ------------------------------------------------------------------
# example: ./build.sh ~/projects/<PROJECT>/src/staticresources/<NAME>.resource
# ------------------------------------------------------------------
# $ ./build.sh ~/Documents/workspace/salesforceorg/Cumulus/src/staticresources/BGEResources.resource.zip


DESTINATION=$1
FILENAME=$(basename $DESTINATION)
FOLDER=$(dirname $DESTINATION)
VERSION=$(git rev-parse HEAD)
BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo $VERSION > .release
echo 'building' $BRANCH '('$VERSION')'
zip -FSr -9 $DESTINATION . -x build.sh *.git* *.sh node_modules node_modules/**\* *bower* gulpfile.js karma* package.json .idea .idea/ .idea/**\* build.xml lib/ngForce local/**\* sandbox/**\* *.py key.pem cert.pem package-lock.json
cat << EOM > "${DESTINATION}-meta.xml"
<?xml version="1.0" encoding="UTF-8"?>
<StaticResource xmlns="http://soap.sforce.com/2006/04/metadata">
    <cacheControl>Public</cacheControl>
    <contentType>application/zip</contentType>
</StaticResource>
EOM
