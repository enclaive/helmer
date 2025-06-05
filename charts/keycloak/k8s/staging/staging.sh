#!/bin/sh
set -ex

REF=$(git branch --show-current)-$(git describe --tags --always --dirty)

docker --context default build -f Dockerfile.staging . -t harbor.enclaive.cloud/emcp/kc-provider:$REF --push
docker tag harbor.enclaive.cloud/emcp/kc-provider:$REF harbor.enclaive.cloud/emcp/kc-provider:staging
docker push harbor.enclaive.cloud/emcp/kc-provider:staging

sed "s;  tag: .*;  tag: $REF;" -i keycloakValuesOverride.staging.yaml

helm upgrade --install --namespace emcp-staging emcp-staging-keycloak oci://registry-1.docker.io/bitnamicharts/keycloak --version 24.4.6 -f keycloakValuesOverride.staging.yaml
