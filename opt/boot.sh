#!/bin/bash

set -e

if [ -n "$DEBUG" ]; then
  set -x
fi

# Vérification des variables d'environnement requises
if [[ -z "$CANONICAL_HOST" ]]; then
  echo >&2 "[ERREUR] La variable d'environnement CANONICAL_HOST doit être définie"
  exit 1
fi

if [[ -z "$BASIC_AUTH_USERNAME" ]] || [[ -z "$BASIC_AUTH_PASSWORD" ]]; then
  echo >&2 "[ERREUR] Les variables BASIC_AUTH_USERNAME et BASIC_AUTH_PASSWORD sont obligatoires"
  exit 1
fi

# Création des répertoires nécessaires
mkdir -p /etc/prometheus/rules
chmod -R 755 /etc/prometheus

# Copie des fichiers de configuration
echo "[INFO] Génération de la configuration Prometheus..."
ruby /app/opt/gen_prometheus_conf.rb > /app/prometheus.yml

# Vérification de la configuration
echo "[INFO] Vérification de la configuration..."
/app/prometheus/promtool check config /app/prometheus.yml

# Création du fichier d'authentification
echo "[INFO] Configuration de l'authentification..."
if [[ -n "$BASIC_AUTH_USERNAME" && -n "$BASIC_AUTH_PASSWORD" ]]; then
  # Installation de htpasswd si nécessaire
  if ! command -v htpasswd &> /dev/null; then
    echo "[INFO] Installation de apache2-utils pour htpasswd..."
    apt-get update && apt-get install -y apache2-utils
  fi
  
  # Création du fichier d'authentification
  echo "[INFO] Création du fichier d'authentification..."
  htpasswd -b -c /etc/prometheus/web_auth.yml "$BASIC_AUTH_USERNAME" "$BASIC_AUTH_PASSWORD"
  chmod 644 /etc/prometheus/web_auth.yml
  
  # Vérification que le fichier a été créé
  if [ ! -f "/etc/prometheus/web_auth.yml" ]; then
    echo "[ERREUR] Impossible de créer le fichier d'authentification"
    exit 1
  fi
  
  echo "[SUCCÈS] Authentification configurée pour l'utilisateur: $BASIC_AUTH_USERNAME"
else
  echo "[ERREUR] Les variables BASIC_AUTH_USERNAME et BASIC_AUTH_PASSWORD doivent être définies"
  exit 1
fi

<<<<<<< HEAD
echo "Using Promscale as Prometheus storage backend"

if [[ -z "$PROMSCALE_AUTH_USERNAME" ]] || [[ -z "$PROMSCALE_AUTH_PASSWORD" ]]; then
  echo >&2 "The environment variables PROMSCALE_AUTH_USERNAME and PROMSCALE_AUTH_PASSWORD are mandatory to connect to Promscale"
  exit -1
fi

r_influx=""
if [[ -n "$INFLUXDB_URL" || -n "$INFLUX_URL" ]]; then
  r_influx="Using InfluxDB as Prometheus remote_write backend"
fi
echo "$r_influx"

echo "Generating the Prometheus configuration file"
ruby /app/gen_prometheus_conf.rb > /app/prometheus.yml

/app/prometheus/prometheus --web.listen-address=0.0.0.0:${PORT} \
=======
# Démarrage de Prometheus
echo "[INFO] Démarrage de Prometheus..."
exec /app/prometheus/prometheus \
  --config.file=/app/prometheus.yml \
  --storage.tsdb.path=/prometheus \
  --web.console.libraries=/app/prometheus/console_libraries \
  --web.console.templates=/app/prometheus/consoles \
  --web.listen-address=:${PORT:-9090} \
>>>>>>> 62787bac3e7326650d0cc6fe7144a5c49aa6994b
  --web.external-url=https://${CANONICAL_HOST} \
  --web.route-prefix="/" \
  --web.enable-lifecycle \
  --storage.tsdb.retention.time=30d
