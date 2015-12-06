#!/bin/bash
############################################################################################################################
#               ### ChaosChrome (CChrome) j_functions.sh (C) ChaOSChriS - chaosware19@gmail.com - 2015 ###                 #
# 													### www.chaosdroid.com ###                                             #
#               ##########################################################################################                 #
#                 this file contains needed functions to build cchrome with jenkins on unix-based systems                  #
# 													                                                                       #
############################################################################################################################
function edit_jobconfig {
#build #changelog
#duration #description
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
function set_gclient_file {
#prepairing build
if [ "$TYPE" = "caf" ]
then
	export GYP_DEFINES="OS=android clang=0"
    cd $SWE_DIR
	[ -f "$BUILDTOOLS_DIR/gclient/.gclient.$BRANCH.caf" ] || exit
	ln -nsf $BUILDTOOLS_DIR/gclient/.gclient.$BRANCH.caf .gclient
	APKNAME=SWE_Browser
    
    if [ -d "$SWE_DIR/src/" ]; then
    cd $SWE_DIR/src/
    REV=$(git log src.chrome.android --pretty=format:'%h' -n 1)
    fi
    
elif [ "$TYPE" = "release" ]
then
	export GYP_DEFINES="OS=android clang=0"
    cd $SWE_DIR
	[ -f "$BUILDTOOLS_DIR/gclient/.gclient.$BRANCH.chaosdroid" ] || exit
	ln -nsf $BUILDTOOLS_DIR/gclient/.gclient.$BRANCH.chaosdroi .gclient
    APKNAME=ChaosChrome
    if [ -d "$CD_DIR/src.chaosdroid/chrome/android/" ]; then
    cd $CD_DIR/src.chaosdroid/chrome/android/
    REV=$(git log HEAD --pretty=format:'%h' -n 1)
    fi
fi
}
############################################################################################################################
function cleanENV {
if [ "$param_cleanbuild" = true ]
then
echo -e "   $blue## [BUILD]$nocolor: cleanENV: do a clean build, cleaning...$nocolor"
if [ -d "$SWE_DIR/src/" ]; then
rm -fr $SWE_DIR/src/
fi
if [ -d "$CD_DIR/src.chaosdroid/chrome/android/" ]; then
rm -fr $CD_DIR/src.chaosdroid/chrome/android/
fi
if [ -d "$CD_DIR/chaosdroid_release/" ]; then
rm -fr $CD_DIR/chaosdroid_release/
fi
echo -e "   $blue## [BUILD]$nocolor: cleanENV: done with cleaning...$nocolor"
fi
}
############################################################################################################################
function checkBuildTools {
if [ $# -eq 1 ] && [ "$1" = "depot_tools" ]
then
cdecho "BUILD" $blue " checkBuildTools: Checking depot_tools ..." $nocolor
cd $SWE_DIR
[ -d "depot_tools" ] || git clone git://codeaurora.org/quic/chrome4sdp/chromium/tools/depot_tools.git > >(while read line; do cdecho "git" $blue "$line" $nocolor >&2; done)
export PATH="$SWE_DIR/depot_tools:$PATH"

elif [ $# -eq 1 ] && [ "$1" = "android-sdks" ]
then
echo -e "   $blue## [BUILD]$nocolor: checkBuildTools: Checking Android SDK extras ...$nocolor"
[ -d "$SWE_DIR/src/third_party/android_tools/sdk/extras/google/google_play_services" ] || echo y | src/build/install-android-sdks.sh > >(while read line; do cdecho "gplay_services" $blue "$line" $nocolor >&2; done)

else
echo -e "   $red## [BUILD]$nocolor: checkBuildTools: dont know $1 =( ...$nocolor"
fi
}
############################################################################################################################
function syncSource {
if [ -d "$SWE_DIR/src/out/" ]; then
rm -fr $SWE_DIR/src/out/
fi
if [ -d "$CD_DIR/chaosdroid_release/" ]; then
rm -fr $CD_DIR/chaosdroid_release/
fi
if [ -d "$SWE_DIR/tmp_release_cchrome" ]; then
rm -fr $SWE_DIR/tmp_release_cchrome
fi
mkdir $CD_DIR/chaosdroid_release

cdecho "BUILD" $blue "syncSource: Initialising sync..." $nocolor
cd $SWE_DIR/src && git checkout -b gclient_m46_$BUILD_NUMBER > >(while read line; do cdecho "git" $blue "syncSource: $line" $nocolor >&2; done)

cd $SWE_DIR
cdecho "BUILD" $blue "syncSource: sync caf-code..." $nocolor
#echo -e "   $blue## [BUILD]$nocolor: syncSource: sync caf-code...$nocolor"
gclient sync -j$NRJOBS  --nohooks --no-nag-max  --delete_unversioned_trees --force --reset> >(while read line; do cdecho "gclient" $blue "$line" $nocolor >&2; done)
echo -e "   $blue## [BUILD]$nocolor: syncSource: Cleaning with git...$nocolor"
gclient recurse -j$NRJOBS git clean -fdx .> >(while read line; do cdecho "gclient" $blue "$line" $nocolor >&2; done)

checkBuildTools "android-sdks"

cd $SWE_DIR/src/
cdecho "DEBUG" $red "checking branches after fresh sync" $nocolor ########################
git branch > >(while read line; do cdecho "DEBUG" $red "$line" $nocolor >&2; done) ########################
git checkout -b cafsync_$BUILD_NUMBER
git commit -a -m $cafsync_commit_msg

git branch > >(while read line; do cdecho "DEBUG" $red "$line" $nocolor >&2; done) ########################

if [ "$param_cleanbuild" = true ] ; then
echo -e "   $blue## [BUILD]$nocolor: syncSource: because we have a clean caf-repo split src/chrome/android/ as subtree into new branch chrome.android.subtree...$nocolor"
echo -e "   $blue## [BUILD]$nocolor: because caf-chromium repo is 8GB+, this will take forever :( ...$nocolor"
cd $SWE_DIR/src/
git subtree split -P chrome/android -b src.chrome.android > >(while read line; do cdecho "git" $blue "$line" $nocolor >&2; done)          
echo -e "   $blue## [BUILD]$nocolor: syncSource: yeah... we are done with splitting (Y)...$nocolor"

else
cd $SWE_DIR/src/
cdecho "DEBUG" $red "checking branches after fresh sync" $nocolor ########################
git branch > >(while read line; do cdecho "DEBUG" $red "$line" $nocolor >&2; done) ########################
echo -e "   $blue## [BUILD]$nocolor: syncSource: updating src/chrome/android/ from caf ...$nocolor"
git subtree pull --prefix=chrome/android origin m46 > >(while read line; do cdecho "git" $blue "$line" $nocolor >&2; done)
newREV=$(git log --pretty=format:'%h' -n 1)
fi

if [ "$TYPE" = "release" ]
then
pushAfterBuild=false
cd $CD_DIR/src.chaosdroid/chrome/android
cdecho "DEBUG" $red "checking branches after fresh sync" $nocolor ########################
git branch > >(while read line; do cdecho "DEBUG" $red "$line" $nocolor >&2; done) ########################
git checkout -b chaosdroidsync_$BUILD_NUMBER > >(while read line; do cdecho "git" $blue "$line" $nocolor >&2; done)
cdecho "DEBUG" $red "checking branches after fresh sync" $nocolor ########################
git branch > >(while read line; do cdecho "DEBUG" $red "$line" $nocolor >&2; done) ########################
echo -e "   $blue## [BUILD]$nocolor: syncSource: updating src.chaosdroid/chrome/android from caf ...$nocolor"
git pull -X subtree=chrome/android $SWE_DIR/src/ src.chrome.android > >(while read line; do cdecho "git" $blue "$line" $nocolor >&2; done) #:m46 
#git subtree pull --prefix=chrome/android $SWE_DIR/src/ src.chrome.android
newREV=$(git log --pretty=format:'%h' -n 1)
git push $CGIT chaosdroidsync_$BUILD_NUMBER:m46 > >(while read line; do cdecho "git" $blue "$line" $nocolor >&2; done)

elif [ "$TYPE" = "caf" ]
then
pushAfterBuild=true
fi

cdecho "BUILD" $blue "syncSource: clean sync branches..." $nocolor
git branch -d gclient_m46_$BUILD_NUMBER && git branch -d cafsync_$BUILD_NUMBER && git branch -d chaosdroidsync_$BUILD_NUMBER > >(while read line; do cdecho "git" $blue "syncSource: $line" $nocolor >&2; done)
}
############################################################################################################################
function gen_changelog {
cd $CD_DIR/src.chaosdroid/chrome/android/
echo -e \
"   $blue$bold#############################################################################################$nocolor"\
"\n   $blue$bold## Project:$nobold$nocolor Chromium Browser for Snapdragon"\
"\n   $blue$bold## Branch:$nobold$nocolor $param_type"\
"\n   $blue$bold## Build-Type:$nobold$nocolor $param_branch"\
"\n   $blue$bold## Build-Number:$nobold$nocolor $BUILD_NUMBER"
"\n   $blue$bold## Revision (current hash):$nobold$nocolor $newREV"\
"\n   $blue$bold#############################################################################################$nocolor"\ 
"\n   $blue$bold## Changelog: :$nobold\n"
git log --pretty=format:'%h (%an) : %s' --graph $REV^..HEAD > >(while read line; do echo -e "   ## $line" >&2; done)
echo -e "$blue$bold   ######################################chaosdroid.com########################################$nocolor"
cd $SWE_DIR
#mytime="$(time ( ls ) 2>&1 1>/dev/null )"
}
############################################################################################################################
function getReady {
apk_string="$APKNAME"_"$TYPE"_"$BRANCH"_"$newREV"
echo -e "   $blue## [BUILD]$nocolor: getReady: Generating Changelog ...$nocolor\n" # blue build string as variable!! TODO 
gen_changelog
gen_changelog >> $CD_DIR/chaosdroid_release/"$apk_string"_changelog.txt
echo -e "   $blue## [BUILD]$nocolor: getReady: Generating Makefiles (runhooks)...$nocolor"
source $SWE_DIR/src/build/android/envsetup.sh
time gclient runhooks -j$NRJOBS > >(while read line; do cdecho "gclient" $blue "$line" $nocolor >&2; done)
}
############################################################################################################################
function buildAPK {
#dl_link="http://chaosdroid.com/jenkins/job/chrome4sdp-beta/$BUILD_NUMBER/artifact/chaosdroid_release/$apk_string.apk"
cdecho "buildAPK" $blue "setting build-description to: APKName:"$apk_string".apk" $nocolor
 echo "download:download: ,link:<a href="$dl_link">$apk_string.apk</a>h"
 echo -e "   $blue## [BUILD]$nocolor: buildAPK: Building "$apk_string".apk ...$nocolor"
 cd $SWE_DIR/src
 time ninja -j$NRJOBS -C $BUILD_FLAVOR $1 > >(while read line; do cdecho "ninja" $blue $line $nocolor >&2; done)
 cp $SWE_DIR/src/out/Release/apks/SWE_Browser.apk $CD_DIR/chaosdroid_release/"$apk_string".apk
}
############################################################################################################################