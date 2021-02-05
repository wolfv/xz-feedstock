#!/usr/bin/env bash

# PLEASE NOTE: This script has been automatically generated by conda-smithy. Any changes here
# will be lost next time ``conda smithy rerender`` is run. If you would like to make permanent
# changes to this script, consider a proposal to conda-smithy so that other feedstocks can also
# benefit from the improvement.

set -xeuo pipefail
export FEEDSTOCK_ROOT="${FEEDSTOCK_ROOT:-/home/conda/feedstock_root}"
source ${FEEDSTOCK_ROOT}/.scripts/logging_utils.sh


endgroup "Start Docker"

startgroup "Configuring conda"
export PYTHONUNBUFFERED=1
export RECIPE_ROOT="${RECIPE_ROOT:-/home/conda/recipe_root}"
export CI_SUPPORT="${FEEDSTOCK_ROOT}/.ci_support"
export CONFIG_FILE="${CI_SUPPORT}/${CONFIG}.yaml"

cat >~/.condarc <<CONDARC

conda-build:
 root-dir: ${FEEDSTOCK_ROOT}/build_artifacts

CONDARC

if [[ "${BUILD_WITH_MAMBABUILD:-0}" == 1 ]]; then
    export GET_BOA=boa
    export BUILD_CMD=mambabuild
    export UPLOAD_PACKAGES=False
else
    export BUILD_CMD=build
fi

conda install --yes --quiet "conda-forge-ci-setup=3" conda-build pip ${GET_BOA:-} -c conda-forge

# set up the condarc
setup_conda_rc "${FEEDSTOCK_ROOT}" "${RECIPE_ROOT}" "${CONFIG_FILE}"

source run_conda_forge_build_setup

# make the build number clobber
make_build_number "${FEEDSTOCK_ROOT}" "${RECIPE_ROOT}" "${CONFIG_FILE}"

if [[ "${HOST_PLATFORM}" != "${BUILD_PLATFORM}" ]]; then
     EXTRA_CB_OPTIONS="${EXTRA_CB_OPTIONS:-} --no-test"
fi

endgroup "Configuring conda"

if [[ "${BUILD_WITH_CONDA_DEBUG:-0}" == 1 ]]; then
    startgroup "Running conda debug"
    if [[ "x${BUILD_OUTPUT_ID:-}" != "x" ]]; then
        EXTRA_CB_OPTIONS="${EXTRA_CB_OPTIONS:-} --output-id ${BUILD_OUTPUT_ID}"
    fi
    conda debug "${RECIPE_ROOT}" -m "${CI_SUPPORT}/${CONFIG}.yaml" \
        ${EXTRA_CB_OPTIONS:-} \
        --clobber-file "${CI_SUPPORT}/clobber_${CONFIG}.yaml"
    endgroup "Running conda debug"
    # Drop into an interactive shell
    /bin/bash
else
    startgroup "Running conda $BUILD_CMD"
    conda $BUILD_CMD "${RECIPE_ROOT}" -m "${CI_SUPPORT}/${CONFIG}.yaml" \
        --suppress-variables ${EXTRA_CB_OPTIONS:-} \
        --clobber-file "${CI_SUPPORT}/clobber_${CONFIG}.yaml"
    endgroup "Running conda build"
    startgroup "Validating outputs"
    validate_recipe_outputs "${FEEDSTOCK_NAME}"
    endgroup "Validating outputs"

    if [[ "${UPLOAD_PACKAGES}" != "False" ]]; then
        startgroup "Uploading packages"
        upload_package --validate --feedstock-name="${FEEDSTOCK_NAME}"  "${FEEDSTOCK_ROOT}" "${RECIPE_ROOT}" "${CONFIG_FILE}"
        endgroup "Uploading packages"
    fi
fi

touch "${FEEDSTOCK_ROOT}/build_artifacts/conda-forge-build-done-${CONFIG}"