#!/bin/sh
set -ex

REF=$(git branch --show-current)-$(git describe --tags --always --dirty)

docker --context default build -f Dockerfile.dev . -t harbor.enclaive.cloud/emcp/kc-provider:$REF --push
docker tag harbor.enclaive.cloud/emcp/kc-provider:$REF harbor.enclaive.cloud/emcp/kc-provider:dev
docker push harbor.enclaive.cloud/emcp/kc-provider:dev

sed "s;  tag: .*;  tag: $REF;" -i keycloakValuesOverride.dev.yaml

helm upgrade --install --namespace emcp-deve emcp-deve-keycloak oci://registry-1.docker.io/bitnamicharts/keycloak --version 24.4.6 -f keycloakValuesOverride.dev.yaml
