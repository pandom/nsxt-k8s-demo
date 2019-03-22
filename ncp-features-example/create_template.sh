#!/bin/bash
# usage
cmdname=`basename $0`
function usage()
{
    echo "Usage: ${cmdname} <version> <feature_name>" 1>&2
}

# check arguments
if [[ $# -ne 2 ]]; then
    usage
    exit 1
fi
export NCP_VERSION="$1"
export FEATURE_NAME="$2"

# main

if [[ -e ./${NCP_VERSION}-${FEATURE_NAME} ]]; then
    echo "Aborted because folder ${NCP_VERSION}-${FEATURE_NAME} already exists"
    exit 1
fi

mkdir -p ./${NCP_VERSION}-${FEATURE_NAME}
cat template/nginx-web-deployments.yaml | envsubst > ./${NCP_VERSION}-${FEATURE_NAME}/nginx-web-deployments.yml
cat template/nginx-web-ingress.yaml | envsubst > ./${NCP_VERSION}-${FEATURE_NAME}/nginx-web-ingress.yml
cat template/nginx-web-service.yaml | envsubst > ./${NCP_VERSION}-${FEATURE_NAME}/nginx-web-service.yml

exit 0
