#!/bin/sh
set -ex
# show available schemes
# xcodebuild -list -project ./Smart4SURE.xcodeproj
if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then
    echo "Testings is disabled due to to issue BRIDGE-1727"
    # bundle exec fastlane test scheme:"Smart4SURE"
fi
if [ "$TRAVIS_PULL_REQUEST" = "false" ]; then
    git clone https://github.com/Sage-Bionetworks/iOSPrivateProjectInfo.git ../iOSPrivateProjectInfo
    bundle exec fastlane ci_archive scheme:"Smart4SURE" export_method:"enterprise"
fi
exit $?
