#!/usr/bin/env bash

set -e

source src/dev/ci_setup/setup_env.sh true

echo " -- KIBANA_DIR='$KIBANA_DIR'"
echo " -- XPACK_DIR='$XPACK_DIR'"
echo " -- PARENT_DIR='$PARENT_DIR'"
echo " -- KIBANA_PKG_BRANCH='$KIBANA_PKG_BRANCH'"
echo " -- TEST_ES_SNAPSHOT_VERSION='$TEST_ES_SNAPSHOT_VERSION'"

###
### copy .bazelrc-ci into $HOME/.bazelrc
###
cp "src/dev/ci_setup/.bazelrc-ci" "$HOME/.bazelrc";

###
### append auth token to buildbuddy into "$HOME/.bazelrc";
###
echo "# Appended by src/dev/ci_setup/setup.sh" >> "$HOME/.bazelrc"
echo "build --remote_header=x-buildbuddy-api-key=$KIBANA_BUILDBUDDY_CI_API_KEY" >> "$HOME/.bazelrc"

###
### install dependencies
###
echo " -- installing node.js dependencies"
yarn kbn bootstrap

###
### Download es snapshots
###
echo " -- downloading es snapshot"
node scripts/es snapshot --download-only;
node scripts/es snapshot --license=oss --download-only;


###
### verify no git modifications
###
GIT_CHANGES="$(git ls-files --modified)"
if [ "$GIT_CHANGES" ]; then
  echo -e "\n${RED}ERROR: 'yarn kbn bootstrap' caused changes to the following files:${C_RESET}\n"
  echo -e "$GIT_CHANGES\n"
  exit 1
fi

###
### rebuild kbn-pm distributable to ensure it's not out of date
###
echo " -- building kbn-pm distributable"
yarn kbn run build -i @kbn/pm

###
### verify no git modifications
###
GIT_CHANGES="$(git ls-files --modified)"
if [ "$GIT_CHANGES" ]; then
  echo -e "\n${RED}ERROR: 'yarn kbn run build -i @kbn/pm' caused changes to the following files:${C_RESET}\n"
  echo -e "$GIT_CHANGES\n"
  exit 1
fi

###
### rebuild plugin list to ensure it's not out of date
###
echo " -- building plugin list docs"
node scripts/build_plugin_list_docs

###
### verify no git modifications
###
GIT_CHANGES="$(git ls-files --modified)"
if [ "$GIT_CHANGES" ]; then
  echo -e "\n${RED}ERROR: 'node scripts/build_plugin_list_docs' caused changes to the following files:${C_RESET}\n"
  echo -e "$GIT_CHANGES\n"
  exit 1
fi
