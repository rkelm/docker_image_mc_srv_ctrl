#!/bin/bash

if [ -z $1 ] ; then
    echo "usage: $(basename $0) <app_version>"
    exit 1
fi

# ***** Configuration *****
# Assign configuration values here or set environment variables.
rconpwd="$BAKERY_RCONPWD"
local_repo_path="$BAKERY_LOCAL_REPO_PATH"
remote_repo_path="$BAKERY_REMOTE_REPO_PATH"
repo_name="mc_srv_ctrl"
install_dir="/opt/mc_srv_ctrl"

# Some options may be set directly in the Dockerfile.


errchk() {
    if [ "$1" != "0" ] ; then
	echo "$2"
	echo "Exiting."
	exit 1
    fi
}

if [ -z "$rconpwd" ] || [ -z "$local_repo_path" ] || [ -z "$remote_repo_path" ] ; then
    errchk 1 'Configuration variables in script not set. Assign values in script or set corresponding environment variables.'
fi

app_version="$1"
image_tag="$app_version"

if [ -n "$image_tag" ] ; then
    local_repo_tag="${local_repo_path}/${repo_name}:${image_tag}"
    remote_repo_tag="${remote_repo_path}/${repo_name}:${image_tag}"    
else
    local_repo_tag="${local_repo_path}:${repo_name}"
    remote_repo_tag="${remote_repo_path}:${repo_name}"
fi

# The project directory is the folder containing this script.
project_dir=$( dirname "$0" )
project_dir=$( ( cd "$project_dir" && pwd ) )
if [ -z "$project_dir" ] ; then
    errck 1 "Error: Could not determine project_dir."
fi
echo "Project directory is ${project_dir}."

# Prepare rootfs.
rootfs="${project_dir}/rootfs"

echo "Cleaning up rootfs from previous build."
rm -frd "$rootfs"

echo "Preparing rootfs."
mkdir -p "${rootfs}${install_dir}"
mkdir -p "${rootfs}${install_dir}/map_data"
mkdir -p "${rootfs}${install_dir}/map_logs"
mkdir -p "${rootfs}${install_dir}/bin"

cp ${project_dir}/mcrcon ${rootfs}${install_dir}/bin/
cp ${project_dir}/mcrcon_LICENSE.txt ${rootfs}${install_dir}/bin/
cp ${project_dir}/run_dummy_process.sh ${rootfs}${install_dir}/bin/
cp ${project_dir}/stop_dummy_process.sh ${rootfs}${install_dir}/bin/
cp ${project_dir}/image_info.txt ${rootfs}/
cp ${project_dir}/bin/* ${rootfs}${install_dir}/bin/

# Build.
echo "Building $local_repo_tag"

# --no-cache
docker build --no-cache --build-arg INSTALL_DIR="${install_dir}" --build-arg RCONPWD="${rconpwd}" "${project_dir}" -t "${local_repo_tag}"
errchk $? 'Docker build failed.'

# Get image id.
image_id=$(docker images -q "${local_repo_tag}")

test -n $image_id
errchk $? 'Could not retrieve docker image id.'
echo "Image id is ${image_id}."

# Tag for Upload to aws repo.
docker tag "${image_id}" "${remote_repo_tag}"
errchk $? "Failed re-tagging image ${image_id}".

# Upload.
echo "Execute the following commands to upload the image to a remote aws repository."
echo '   $(aws ecr get-login --no-include-email --region eu-central-1)'
echo "   docker push ${remote_repo_tag}"
