#!/bin/bash
############################################################################################################################
#               ### ChaosChrome (CChrome) j_functions.sh (C) ChaOSChriS - chaosware19@gmail.com - 2015 ###                 #
# 													### www.chaosdroid.com ###                                             #
#               ##########################################################################################                 #
#                 this file contains needed functions to build cchrome with jenkins on unix-based systems                  #
# 													                                                                       #
############################################################################################################################
function edit_jobconfig { #possible with cli; instead of plugins, for build name and alias?: TODO
#build #changelog
#duration #description
#build name #alias
opt=$1
xml_path=$jobdir"/"$2.xml
xml_file=$2.xml
tag=$3
value=$4
if [ "$opt" = "set" ]
then
cd $xml_path
	sed -i "s/\(<$tag.*>\).*\(<\/$tag.*\)/\1$value\2/" $xml_file
elif [ "$opt" = "get" ]
then
cd $xml_path
	return=$(sed -n "/$tag/{s/.*<$tag>//;s/<\/$tag.*//;p;}" $xml_file) 
else
	echo -e "   $blue[edit_jobconfig]$red[error]$nocolor don know an option like: $opt =("
fi 
}
############################################################################################################################
function cdecho {
msg=$3
app=$1
appcolor=$2
txtcolor=$4
if [ $# -eq 1 ] && [ "$1" = "sep" ] ; then
echo -e "   $blue$bold#############################################################################################$nocolor"
else
echo -e "   $appcolor$bold## [$app]$nobold$txtcolor: $msg$nocolor"
fi
}
############################################################################################################################
function preparingBuild { 
SYNCTYPE=$1

cdecho "BUILD" $blue "preparingBuild: Prepairing build environment..." $nocolor

[ -f "$BUILDTOOLS_DIR/gclient/.gclient.$BRANCH.$SYNCTYPE" ] || exit
ln -nsf $BUILDTOOLS_DIR/gclient/.gclient.$BRANCH.$SYNCTYPE $SWE_DIR/.gclient

cdecho "BUILD" $blue "preparingBuild: set gclient-config" $nocolor
cdecho "BUILD" $blue "preparingBuild: $BUILDTOOLS_DIR/gclient/.gclient.$BRANCH.$SYNCTYPE -> $SWE_DIR/.gclient" $nocolor

if [ -d "$SWE_DIR/src/" ]; then
    cd $SWE_DIR/src/ && cafREV=$(git log src.chrome.android --pretty=format:'%h' -n 1)
    cdecho "BUILD" $blue "preparingBuild: saved current caf revision ($cafREV)" $nocolor
fi

if [ -d "$CD_DIR/src.chaosdroid/chrome/android/" ]; then
    cd $CD_DIR/src.chaosdroid/chrome/android/ && cdREV=$(git log HEAD --pretty=format:'%h' -n 1)
    cdecho "BUILD" $blue "preparingBuild: saved current chaosdroid revision ($cdREV)" $nocolor
fi

if [ -d "$BUILDTOOLS_DIR" ]; then
cd $BUILDTOOLS_DIR && btREV=$(git log HEAD --pretty=format:'%h' -n 1)
cdecho "BUILD" $blue "preparingBuild: saved current buildtools revision ($btREV)" $nocolor
fi

if [ "$SYNCTYPE" = "caf" ]
then
	export GYP_DEFINES="OS=android clang=0"
	APKNAME=SWE_Browser
elif [ "$SYNCTYPE" = "chaosdroid" ]
then
	export GYP_DEFINES="OS=android clang=0" #cd_channel;webrefiner;gsync
    APKNAME=ChaosChrome    
fi

if [ "$param_exp" ] ; then 
	APKNAME+="_exp"
	cd $SWE_DIR
	[ -f "$BUILDTOOLS_DIR/gclient/.gclient.$BRANCH.$SYNCTYPE.exp" ] || exit
	ln -nsf $BUILDTOOLS_DIR/gclient/.gclient.$BRANCH.$SYNCTYPE.exp $SWE_DIR/.gclient
	cdecho "BUILD" $blue "preparingBuild: set exp gclient-config" $nocolor
	cdecho "BUILD" $blue "preparingBuild: $BUILDTOOLS_DIR/gclient/.gclient.$BRANCH.$SYNCTYPE.exp -> $SWE_DIR/.gclient" $nocolor
	# cp exp gclient=>ssh
fi
}
############################################################################################################################
function cleanENV {
if [ "$param_cleanbuild" = true ]
then
cdecho "BUILD" $blue "cleanENV: do a clean build, cleaning..." $nocolor

if [ -d "$SWE_DIR/src/" ]; then
rm -fr $SWE_DIR/src/
fi

if [ -d "$CD_DIR/src.chaosdroid/chrome/android/" ]; then
rm -fr $CD_DIR/src.chaosdroid/chrome/android/
fi

if [ -d "$CD_DIR/chaosdroid_release/" ]; then
rm -fr $CD_DIR/chaosdroid_release/
fi

cdecho "BUILD" $blue "cleanENV: done with cleaning..." $nocolor
fi
}
############################################################################################################################
function checkBuildTools {
if [ $# -eq 1 ] && [ "$1" = "depot_tools" ]
then
cdecho "BUILD" $blue "checkBuildTools: Checking depot_tools ..." $nocolor
cd $SWE_DIR
[ -d "depot_tools" ] || echo y | git clone git://codeaurora.org/quic/chrome4sdp/chromium/tools/depot_tools.git > >(while read line; do cdecho "git" $blue "$line" $nocolor >&2; done)
export PATH="$SWE_DIR/depot_tools:$PATH"

elif [ $# -eq 1 ] && [ "$1" = "android-sdks" ]
then
cdecho "BUILD" $blue "checkBuildTools: Checking Android SDK extras ..." $nocolor
[ -d "$SWE_DIR/src/third_party/android_tools/sdk/extras/google/google_play_services" ] || echo y | src/build/install-android-sdks.sh > >(while read line; do cdecho "gplay_services" $blue "$line" $nocolor >&2; done)

else
cdecho "BUILD" $red "checkBuildTools: dont know $1 =( ..." $nocolor
fi
}
############################################################################################################################
function syncSource {
SYNCTYPE=$1

if [ -d "$SWE_DIR/src/out/" ]; then
rm -fr $SWE_DIR/src/out/
fi

if [ -d "$CD_DIR/chaosdroid_release/" ]; then
rm -fr $CD_DIR/chaosdroid_release/
mkdir $CD_DIR/chaosdroid_release
fi

if [ -d "$SWE_DIR/src/" ]; then
cdecho "BUILD" $blue "syncSource: Initialising sync..." $nocolor
cd $SWE_DIR/src 
git checkout -b gclient_m46_$BUILD_NUMBER > >(while read line; do cdecho "git" $blue "syncSource: $line" $nocolor >&2; done)
fi

if [ "$SYNCTYPE" = "caf" ]
then
preparingBuild caf
cd $SWE_DIR
cdecho "BUILD" $blue "syncSource: sync caf-code..." $nocolor
gclient sync -j$NRJOBS  --nohooks --no-nag-max  --delete_unversioned_trees --force --reset> >(while read line; do cdecho "gclient" $blue "$line" $nocolor >&2; done)

cdecho "BUILD" $blue "syncSource: Cleaning with git..." $nocolor
gclient recurse -j$NRJOBS git clean -fdx .> >(while read line; do cdecho "gclient" $blue "$line" $nocolor >&2; done)

checkBuildTools "android-sdks"

cd $SWE_DIR/src/
git checkout -b cafsync_$BUILD_NUMBER
git commit -m $cafsync_commit_msg

if [ "$param_cleanbuild" = true ] ; then
cdecho "BUILD" $blue "syncSource: because we have a clean caf-repo split src/chrome/android/ as subtree into new branch chrome.android.subtree..." $nocolor
cdecho "BUILD" $blue "syncSource: caf-chromium repo is 8GB+, this will take forever :( ..." $nocolor
cd $SWE_DIR/src/
git subtree split -P chrome/android -b src.chrome.android > >(while read line; do cdecho "git" $blue "$line" $nocolor >&2; done)          
cdecho "BUILD" $blue "syncSource: yeah... we are done with splitting (Y)..." $nocolor
caf_newREV=$(git log src.chrome.android --pretty=format:'%h' -n 1)
else
cd $SWE_DIR/src/
cdecho "BUILD" $blue "syncSource: updating src/chrome/android/ from caf ..." $nocolor
git subtree pull --prefix=chrome/android origin m46 > >(while read line; do cdecho "git" $blue "$line" $nocolor >&2; done)
caf_newREV=$(git log src.chrome.android --pretty=format:'%h' -n 1)
fi

elif [ "$SYNCTYPE" = "chaosdroid" ]
then
preparingBuild chaosdroid
cd $CD_DIR/src.chaosdroid/chrome/android
git checkout -b chaosdroidsync_$BUILD_NUMBER > >(while read line; do cdecho "git" $blue "$line" $nocolor >&2; done)
cdecho "BUILD" $blue "syncSource: updating src.chaosdroid/chrome/android from caf ..." $nocolor
git pull -X subtree=chrome/android $SWE_DIR/src/ src.chrome.android > >(while read line; do cdecho "git" $blue "$line" $nocolor >&2; done) #:m46 
#git subtree pull --prefix=chrome/android $SWE_DIR/src/ src.chrome.android
cd_newREV=$(git log --pretty=format:'%h' -n 1)
git push $CGIT chaosdroidsync_$BUILD_NUMBER:m46 > >(while read line; do cdecho "git" $blue "$line" $nocolor >&2; done)
fi

cdecho "BUILD" $blue "syncSource: clean sync branches..." $nocolor
git branch -d gclient_m46_$BUILD_NUMBER && git branch -d cafsync_$BUILD_NUMBER && git branch -d chaosdroidsync_$BUILD_NUMBER > >(while read line; do cdecho "git" $blue "syncSource: $line" $nocolor >&2; done)
}
############################################################################################################################
function gen_changelog {
cdecho "BUILD" $blue "gen_changelog: Generating Changelog ..." $nocolor
#TODO: integrate buildtools repo rev & generate new file
SYNCTYPE=$1
beforeREV=0
afterREV=0
changelog=""

if [ "$SYNCTYPE" = "caf" ]
then
beforeREV=$cafREV
afterREV=$caf_newREV
cd $SWE_DIR/src/
git log src.chrome.android --pretty=format:'%h (%an) : %s' --graph $beforeREV^..$afterREV > >(while read line; do changelog+="   ## $line" >&2; done)

elif [ "$SYNCTYPE" = "chaosdroid" ]
then
beforeREV=$cdREV
afterREV=$cd_newREV
cd $CD_DIR/src.chaosdroid/chrome/android/
git log --pretty=format:'%h (%an) : %s' --graph $beforeREV^..$afterREV > >(while read line; do changelog+="   ## $line" >&2; done)
fi

apk_string="$APKNAME"_"$SYNCTYPE"_"$BRANCH"_"$afterREV"

echo -e \
"   #############################################################################################$nocolor"\
"\n   ## Project: Chromium Browser for Snapdragon"\
"\n   ## Branch: $param_type"\
"\n   ## Build-Type: $SYNCTYPE"\
"\n   ## Build-Number: $BUILD_NUMBER"\
"\n   ## Revision: $afterREV"\
"\n   #############################################################################################$nocolor"\ 
"\n   ## Changelog:"\
"\n   ##\n"\
"$changelog" >> $CD_DIR/chaosdroid_release/"$apk_string"_changelog.txt

cdecho "BUILD" $blue "gen_changelog: Changelog successful written to: " $nocolor
cdecho "BUILD" $blue "gen_changelog: $CD_DIR/chaosdroid_release/$apk_string_changelog.txt" $nocolor

echo -e \
"   $blue$bold#############################################################################################$nocolor"\
"\n   $blue$bold## Project:$nobold$nocolor Chromium Browser for Snapdragon"\'
"\n   $blue$bold## Branch:$nobold$nocolor $param_branch"\
"\n   $blue$bold## Build-Type:$nobold$nocolor $SYNCTYPE"\
"\n   $blue$bold## Build-Number:$nobold$nocolor $BUILD_NUMBER"\
"\n   $blue$bold## Revision (current hash):$nobold$nocolor $afterREV"\
"\n   $blue$bold#############################################################################################$nocolor"\ 
"\n   $blue$bold## Changelog: :$nobold\n"\
"$changelog"

echo -e "$blue$bold   ######################################chaosdroid.com########################################$nocolor"
cd $SWE_DIR
#mytime="$(time ( ls ) 2>&1 1>/dev/null )"
}
############################################################################################################################
function getReady {
#cdecho "BUILD" $blue "getReady: Generating Changelog ..." $nocolor
# gen_changelog
cdecho "BUILD" $blue "getReady: Generating Makefiles (runhooks)..." $nocolor
source $SWE_DIR/src/build/android/envsetup.sh
time gclient runhooks -j$NRJOBS > >(while read line; do cdecho "gclient" $blue "$line" $nocolor >&2; done)
}
############################################################################################################################
function buildAPK {
#dl_link="http://chaosdroid.com/jenkins/job/chrome4sdp-beta/$BUILD_NUMBER/artifact/chaosdroid_release/$apk_string.apk"
cdecho "buildAPK" $blue "setting build-description to: APKName:"$apk_string".apk" $nocolor
 cdecho "BUILD" $blue "buildAPK: Building "$apk_string".apk ..." $nocolor
 cd $SWE_DIR/src
 time ninja -j$NRJOBS -C $BUILD_FLAVOR $1 > >(while read line; do cdecho "ninja" $blue "$line" $nocolor >&2; done)
 cp $SWE_DIR/src/out/Release/apks/SWE_Browser.apk $CD_DIR/chaosdroid_release/"$apk_string".apk
}
############################################################################################################################