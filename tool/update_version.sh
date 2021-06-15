#!/bin/bash
releaseSDKVersion="$(sed -n -e 's/^.*version: //p' pubspec.yaml)"

echo "The current version is : $releaseSDKVersion"

 # update FLagShip version in flagship_version.dart 

sdkVersionFilepath="lib/flagship_version.dart"
sdkVersionKey="FlagshipVersion"

printf "\tUpdating ${sdkVersionKey} to ${releaseSDKVersion}.\n"
sed -i '' -e "s/${sdkVersionKey}[ ]*=.*\"\(.*\)\"/${sdkVersionKey} = \"${releaseSDKVersion}\"/g" ${sdkVersionFilepath}

printf "Verifying ${sdkVersionKey} from ${sdkVersionFilepath}\n";
verifySdkVersion=$(sed -n "s/.*${sdkVersionKey} = \"\(.*\)\".*/\1/p" ${sdkVersionFilepath})

if [ "${verifySdkVersion}" == "${releaseSDKVersion}" ]
then
    printf "\flagship_version.dart file verified: ${releaseSDKVersion} === ${verifySdkVersion}\n"
else
    printf "\n flagship_version.dart file has an error: [${verifySdkVersion}]";
    exit 1
fi