############################################################################################################################
#                          ### ChaosChrome (CChrome) buildme (C) ChaOSChriS - chaosware19@gmail.com - 2015 ###             #
# 													### www.chaosdroid.com ###                                             #
############################################################################################################################
# vars
blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocolor='\033[0m'
green='\e[0;32m'
bold='\e[1m'
nobold='\e[21m'
tab="   "
c_format="$tab## "
last_build_number=$BUILD_NUMBER -1
lastbuild_dir="$JENKINS_HOME/jobs/chrome4sdp-beta/builds/$last_build_number"
jobdir="$JENKINS_HOME/jobs/chrome4sdp-beta/builds/$BUILD_NUMBER"
SWE_DIR=$WORKSPACE
BUILD_FLAVOR=out/Release
BRANCH=$param_branch
TYPE=$param_type
NRJOBS=$(( $(nproc) * 2 ))
CGIT=git@github.com:ChaOSChriS/chaoschrome_beta.git
CAFGIT=git://codeaurora.org/quic/chrome4sdp/chromium/src
cafsync_commit_msg="caf chromium build-tools src sync #"$BUILD_NUMBER_$(date +"%m/%d/%Y_%H:%M:%S")"\n\n"$c_format"Project: Chromium Browser for Snapdragon\n"$c_format"Branch:"$BRANCH"\n"$c_format"Build-Type:"$TYPE"\n"$c_format"Build-Number:"$BUILD_NUMBER
############################################################################################################################

# import functions
source $SWE_DIR/src.chaosdroid/buildtools/j_functions.sh

############################################################################################################################

# start
#last_build_name=$(edit_jobconfig get build displayName)
#lbt=$(edit_jobconfig get build duration)
#last_build_time=$(date -d $lbt -u +%H:%M:%S)
clear && 	echo -e "$nocolor\n\n$bold"
echo -e "$tab$red..######..##.....##....###.....#######...######..########..########...#######..####.########. "
echo -e "$tab$red.##....##.##.....##...##.##...##.....##.##....##.##.....##.##.....##.##.....##..##..##.....## "
echo -e "$tab$red.##.......##.....##..##...##..##.....##.##.......##.....##.##.....##.##.....##..##..##.....## "
echo -e "$tab$red.##.......#########.##.....##.##.....##..######..##.....##.########..##.....##..##..##.....## "
echo -e "$tab$red.##.......##.....##.#########.##.....##.......##.##.....##.##...##...##.....##..##..##.....## "
echo -e "$tab$red.##....##.##.....##.##.....##.##.....##.##....##.##.....##.##....##..##.....##..##..##.....## "
echo -e "$tab$red..######..##.....##.##.....##..#######...######..########..##.....##..#######..####.########. "
sleep 		1
cdecho sep
echo -e \
"$tab$blue$bold## Project:$nobold$nocolor Chromium Browser for Snapdragon\n"\
"$tab$blue$bold## Branch:$nobold$nocolor $param_branch\n"\
"$tab$blue$bold## Build-Type:$nobold$nocolor $param_type\n"\
"$tab$blue$bold## Build-Number:$nobold$nocolor $BUILD_NUMBER"
cdecho sep
#"\n   ## Last Build:$nobold  $last_build_name"
#"\n   $bold## Build duration:$nobold $last_build_time"
#"\n   $bold## Build state:$nobold  $(edit_jobconfig get build result)"

############################################################################################################################

#prepairing built environment
cdecho "INIT" $blue "initializing built environment..." $nocolor
sleep 1
cdecho "INIT" $blue "setting build-name to: #$BUILD_NUMBER: $APKNAME" $nocolor
sleep 1
cdecho "INIT" $blue "setting build-description to: build-Type:$param_type,branch:$param_branch" $nocolor
sleep 1
cdecho sep

############################################################################################################################

#building
set_gclient_file
cleanENV
checkBuildTools "depot_tools"
time syncSource
time getReady
time buildAPK swe_browser_apk
#time buildAPK content_shell_apk
#time buildAPK chrome_shell_apk

############################################################################################################################

#after push (type=caf only)
if [ "$pushAfterBuild" = true ] ; then
cd $SWE_DIR/src.chaosdroid/chrome/android
git checkout -b chaosdroidsync_$BUILD_NUMBER > >(while read line; do cdecho "git" $blue $line $nocolor >&2; done)
echo -e "   $blue## [BUILD]$nocolor: syncSource: updating chaosdroid remote repository ...$nocolor"
git pull -X subtree=chrome/android $SWE_DIR/src/ src.chrome.android #:m46
#git subtree pull --prefix=chrome/android $SWE_DIR/src/ src.chrome.android
git push $CGIT chaosdroidsync_$BUILD_NUMBER:m46 > >(while read line; do cdecho "git" $blue $line $nocolor >&2; done)
fi

############################################################################################################################

#finished
echo -e "   $green## [BUILD]: FINISHED =)  ...$nocolor"

