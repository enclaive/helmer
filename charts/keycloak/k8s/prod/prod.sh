#!/bin/sh
set -ex

REF=$(git branch --show-current)-$(git describe --tags --always --dirty)

docker --context default build -f Dockerfile.prod . -t harbor.enclaive.cloud/emcp/kc-provider:$REF --push
docker tag harbor.enclaive.cloud/emcp/kc-provider:$REF harbor.enclaive.cloud/emcp/kc-provider:prod
docker push harbor.enclaive.cloud/emcp/kc-provider:prod

sed "s;  tag: .*;  tag: $REF;" -i keycloakValuesOverride.prod.yaml

helm upgrade --install --namespace emcp-prod emcp-prod-keycloak oci://registry-1.docker.io/bitnamicharts/keycloak --version 24.4.6 -f keycloakValuesOverride.prod.yaml
