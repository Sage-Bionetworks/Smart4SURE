#!/bin/sh
set -ex
# show available schemes
# xcodebuild -list -project ./Smart4SURE.xcodeproj
# run on pull request
if [ "$TRAVIS_PULL_REQUEST" = "false" ]; then
  fastlane archive scheme:"Smart4SURE"
  exit $?
fi
