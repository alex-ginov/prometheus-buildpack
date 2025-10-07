#!/bin/bash

if [ -n "$DEBUG" ]; then
  set -x
fi

if [[ -z "$CANONICAL_HOST" ]]; then
  echo >&2 "The environment variable CANONICAL_HOST must be set"
  exit -1
fi

if [[ -z "$BASIC_AUTH_USERNAME" ]] || [[ -z "$BASIC_AUTH_PASSWORD" ]]; then
  echo >&2 "The environment variables BASIC_AUTH_USERNAME and BASIC_AUTH_PASSWORD are mandatory to configure the Prometheus Basic Auth"
  exit -1
fi

# Création des dossiers dans /app où nous avons les droits
mkdir -p /app/prometheus/rules
mkdir -p /app/prometheus/rules.d

echo "Generating the Prometheus configuration file"
ruby /app/gen_prometheus_conf.rb > /app/prometheus/prometheus.yml

htpasswd -b -c /app/prometheus/web_auth.yml "$BASIC_AUTH_USERNAME" "$BASIC_AUTH_PASSWORD"
chmod 644 /app/prometheus/web_auth.yml
  
# Vérification que le fichier a été créé
if [ ! -f "/app/prometheus/web_auth.yml" ]; then
  echo >&2 "The file /app/prometheus/web_auth.yml has not been created"
  exit -1
fi

/app/prometheus/prometheus --web.listen-address=0.0.0.0:${PORT} \
  --web.external-url=https://${CANONICAL_HOST} \
  --web.route-prefix="/"
