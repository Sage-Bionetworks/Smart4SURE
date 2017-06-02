#!/bin/sh
set -ex
if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then     # on pull requests
    echo "PRs do not have access to secrets so we run tests post-merge"
    echo "https://docs.travis-ci.com/user/pull-requests/#Pull-Requests-and-Security-Restrictions"
elif [[ -z "$TRAVIS_TAG" && "$TRAVIS_BRANCH" == "master" ]]; then  # non-tag commits to master branch
    git clone https://github.com/Sage-Bionetworks/iOSPrivateProjectInfo.git ../iOSPrivateProjectInfo
    FASTLANE_EXPLICIT_OPEN_SIMULATOR=2 bundle exec fastlane scan
    bundle exec fastlane ci_archive scheme:"Smart4SURE" export_method:"enterprise"
fi
exit $?
