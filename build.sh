#!/usr/bin/env bash

# This script uses arg $1 (name of *.jsonnet file to use) to generate the manifests/*.yaml files.

set -e
set -x
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

# Make sure to start with a clean 'manifests' dir
rm -rf environments/kubernetes/manifests
mkdir environments/kubernetes/manifests

jsonnet -J vendor -m environments/kubernetes/manifests environments/kubernetes/main.jsonnet | xargs -I{} sh -c 'cat {} | gojsontoyaml > {}.yaml' -- {}
find environments/kubernetes/manifests -type f ! -name '*.yaml' -delete

# Make sure to start with a clean 'manifests' dir
rm -rf environments/openshift/manifests
mkdir environments/openshift/manifests

jsonnet -J vendor environments/openshift/main.jsonnet | gojsontoyaml >environments/openshift/manifests/observatorium-template.yaml
jsonnet -J vendor environments/openshift/jaeger.jsonnet | gojsontoyaml >environments/openshift/manifests/jaeger-template.yaml
jsonnet -J vendor environments/openshift/conprof.jsonnet | gojsontoyaml >environments/openshift/manifests/conprof-template.yaml
find environments/openshift/manifests -type f ! -name '*.yaml' -delete

# Make sure to start with a clean 'servicemonitors' dir
rm -rf environments/sre/servicemonitors
mkdir environments/sre/servicemonitors

jsonnet -J vendor -m environments/sre/servicemonitors environments/sre/servicemonitors.jsonnet | xargs -I{} sh -c 'cat {} | gojsontoyaml > {}.yaml' -- {}
find environments/sre/servicemonitors -type f ! -name '*.yaml' -delete

# Make sure to start with a clean 'prometheusrules' dir
rm -rf environments/sre/prometheusrules
mkdir environments/sre/prometheusrules

jsonnet -J vendor -m environments/sre/prometheusrules environments/sre/prometheusrules.jsonnet | xargs -I{} sh -c 'cat {} | gojsontoyaml > {}.yaml' -- {}
find environments/sre/prometheusrules -type f ! -name '*.yaml' -delete

# Make sure to start with a clean 'grafana' dir
rm -rf environments/sre/grafana
mkdir environments/sre/grafana

jsonnet -J vendor -m environments/sre/grafana environments/sre/grafana.jsonnet | xargs -I{} sh -c 'cat {} | gojsontoyaml > {}.yaml' -- {}
find environments/sre/grafana -type f ! -name '*.yaml' -delete
