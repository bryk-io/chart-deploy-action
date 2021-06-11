#!/bin/sh -eu

# Install kubeconfig file
echo "${KUBECTL_CONFIG}" | base64 -d > /tmp/config.yml
chmod 400 /tmp/config.yml

# Install values.yml file
echo "${CHART_VALUES}" | base64 -d > /tmp/values.yml
chmod 400 /tmp/values.yml

# Collect additional parameters
EXTRA_ARGS=""
if [ -n "${INPUT_VERSION}" ]; then
  EXTRA_ARGS="${EXTRA_ARGS} --set image.tag=${INPUT_VERSION} --set image.version=${INPUT_VERSION}"
fi
if [ "${INPUT_ATOMIC}" = "yes" ]; then
  EXTRA_ARGS="${EXTRA_ARGS} --atomic"
fi
if [ "${INPUT_NO-HOOKS}" = "yes" ]; then
  EXTRA_ARGS="${EXTRA_ARGS} --no-hooks"
fi
if [ "${INPUT_FORCE}" = "yes" ]; then
  EXTRA_ARGS="${EXTRA_ARGS} --force"
fi

# Run deployment operation
helm upgrade ${INPUT_NAME} ${INPUT_CHARTS} \
--kubeconfig /tmp/config.yml \
--values /tmp/values.yml \
--namespace "${INPUT_NAMESPACE}" \
--timeout "${INPUT_TIMEOUT}" \
--install \
--cleanup-on-fail \
--wait \
--debug ${EXTRA_ARGS}
