#!/bin/bash

./test/config_cci.sh

# master branch test
if [ "$HEROKU_TEST_RUN_BRANCH" == "master" ]; then
    # Create scratch org config as default org
    cci org scratch browsertest_classic browsertests_master --default

    # Install latest beta
    cci flow run ci_beta_install
    exit_status=$?
    if [ "$exit_status" = "1" ]; then
        echo "Flow execution failed, failing test"
        cci org scratch_delete browsertests_master
        exit 1
    fi

    # Run the browser tests
    cci flow run ci_browsertests
    exit_status=$?

    # Delete the scratch org
    cci org scratch_delete browsertests_master
    if [ "$exit_status" = "1" ]; then
        echo "Flow execution failed, failing test"
        exit 1
    fi
# All other branches
else
    # Create scratch org config as default org
    cci org scratch browsertest_classic browsertests_feature --default

    # Deploy unmanaged metadata
    cci flow run dev_org
    exit_status=$?
    if [ "$exit_status" = "1" ]; then
        echo "Flow execution failed, failing test"
        cci org scratch_delete browsertests_feature
        exit 1
    fi

    # Run the browser tests
    cci flow run ci_browsertests
    exit_status=$?

    # Delete the scratch org
    cci org scratch_delete browsertests_feature
    if [ "$exit_status" = "1" ]; then
        echo "Flow execution failed, failing test"
        exit 1
    fi
fi
