#!/bin/bash
echo "build-Type:$param_type,branch:$param_branch"
if [ "$param_type" = "caf" ] ; then
APKNAME=SWE_Browser
fi
if [ "$param_type" == "release" ] ; then
APKNAME=ChaosChrome
fi
if [ "$param_exp" ] ; then 
APKNAME=$APKNAME"_exp"
fi
if [ ! -d "$WORKSPACE/chaosdroid/" ]; then
mkdir $WORKSPACE/chaosdroid/
fi
echo $APKNAME > "$WORKSPACE/chaosdroid/env_job_version_name"
