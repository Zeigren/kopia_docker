#!/bin/bash

. /env_secrets_expand.sh

set -e

# -------------------------------------------------------------------------------
echo "setting environment variables"

# Specify the config file to use
if [ -z "${KOPIA_CONFIG_PATH}" ]; then
  echo "set KOPIA_CONFIG_PATH"
  export KOPIA_CONFIG_PATH=/app/config/repository.config
fi

# Directory where log files should be written
if [ -z "${KOPIA_LOG_DIR}" ]; then
  echo "set KOPIA_LOG_DIR"
  export KOPIA_LOG_DIR=/app/logs
fi

# Cache directory
if [ -z "${KOPIA_CACHE_DIRECTORY}" ]; then
  echo "set KOPIA_CACHE_DIRECTORY"
  export KOPIA_CACHE_DIRECTORY=/app/cache
fi

# Persist credentials
if [ -z "${KOPIA_PERSIST_CREDENTIALS_ON_CONNECT}" ]; then
  echo "set KOPIA_PERSIST_CREDENTIALS_ON_CONNECT"
  export KOPIA_PERSIST_CREDENTIALS_ON_CONNECT=false
fi

# Periodically check for Kopia updates on GitHub
if [ -z "${KOPIA_CHECK_FOR_UPDATES}" ]; then
  echo "set KOPIA_CHECK_FOR_UPDATES"
  export KOPIA_CHECK_FOR_UPDATES=false
fi

# Set file extensions to never compress
if [ -z "${DE_KOPIA_NEVER_COMPRESS}" ]; then
  echo "set DE_KOPIA_NEVER_COMPRESS"
  export DE_KOPIA_NEVER_COMPRESS=7z,rar,zip,bz,bz2,gz,lzma,lzo,tbz2,tgz,txz,xz,zipx
fi

# HTTP server username (basic auth)
if [ -z "${KOPIA_SERVER_USERNAME}" ]; then
  echo "set KOPIA_SERVER_USERNAME"
  export KOPIA_SERVER_USERNAME=kopia
fi

# HTTP server password (basic auth)
if [ ! -z "${DE_KOPIA_SERVER_PASSWORD}" ]; then
  echo "set KOPIA_SERVER_PASSWORD"
  export KOPIA_SERVER_PASSWORD=${DE_KOPIA_SERVER_PASSWORD}
fi

# Repository password
if [ ! -z "${DE_KOPIA_REPOSITORY_PASSWORD}" ]; then
  echo "set KOPIA_PASSWORD"
  export KOPIA_PASSWORD=${DE_KOPIA_REPOSITORY_PASSWORD}
fi

# Client password
if [ ! -z "${DE_KOPIA_CLIENT_PASSWORD}" ]; then
  echo "set KOPIA_PASSWORD"
  export KOPIA_PASSWORD=${DE_KOPIA_CLIENT_PASSWORD}
fi

# Force particular auth cookie signing key
if [ ! -z "${DE_KOPIA_AUTH_COOKIE_SIGNING_KEY}" ]; then
  echo "set KOPIA_AUTH_COOKIE_SIGNING_KEY"
  export KOPIA_AUTH_COOKIE_SIGNING_KEY=${DE_KOPIA_AUTH_COOKIE_SIGNING_KEY}
fi

# Azure storage account key(overrides AZURE_STORAGE_KEY environment variable
if [ ! -z "${DE_AZURE_STORAGE_KEY}" ]; then
  echo "set AZURE_STORAGE_KEY"
  export AZURE_STORAGE_KEY=${DE_AZURE_STORAGE_KEY}
fi

# Secret key (overrides B2_KEY environment variable)
if [ ! -z "${DE_B2_KEY}" ]; then
  echo "set B2_KEY"
  export B2_KEY=${DE_B2_KEY}
fi

# Secret access key (overrides AWS_SECRET_ACCESS_KEY environment variable)
if [ ! -z "${DE_AWS_SECRET_ACCESS_KEY}" ]; then
  echo "set AWS_SECRET_ACCESS_KEY"
  export AWS_SECRET_ACCESS_KEY=${DE_AWS_SECRET_ACCESS_KEY}
fi

# Session token (overrides AWS_SESSION_TOKEN environment variable)
if [ ! -z "${DE_AWS_SESSION_TOKEN}" ]; then
  echo "set AWS_SESSION_TOKEN"
  export AWS_SESSION_TOKEN=${DE_AWS_SESSION_TOKEN}
fi

# WebDAV password (overrides KOPIA_WEBDAV_PASSWORD environment variable)
if [ ! -z "${DE_WEBDAV_PASSWORD}" ]; then
  echo "set KOPIA_WEBDAV_PASSWORD"
  export KOPIA_WEBDAV_PASSWORD=${DE_WEBDAV_PASSWORD}
fi

# -------------------------------------------------------------------------------
echo "configuring kopia"
# Server first boot
# create repository on first boot
if [ ! -z "${DE_KOPIA_FIRST_BOOT}" ]; then

  echo "configuring API server repository"

  if [ -z "${DE_KOPIA_BLOCK_HASH}" ]; then
    echo "benchmarking crypto"
    kopia benchmark crypto --repeat 100 >/app/config/crypto.txt
    blockhash=$(tail -1 /app/config/crypto.txt | grep -oP 'block-hash(\S*)' | grep -oP '[A-Z](\S*)')
    echo "best blockhash option $blockhash"
    export DE_KOPIA_BLOCK_HASH=$blockhash
  fi

  if [ -z "${DE_KOPIA_COMPRESSION}" ]; then
    echo "benchmarking compression"
    kopia benchmark compression --verify-stable --repeat 100 >/app/config/compression.txt
    compression=$(grep -oP ' 0. (\S*)' /app/config/compression.txt | grep -oP '[a-zA-Z].*')
    echo "best option $compression"
    export DE_KOPIA_COMPRESSION=$compression
  fi
fi

# https://kopia.io/docs/reference/command-line/common/repository-create-azure/
if [ ! -z "${DE_AZURE_STORAGE_KEY}" ]; then
  if [ ! -z "${DE_KOPIA_FIRST_BOOT}" ]; then
    echo "create Azure repository"
    kopia repository create azure \
      --block-hash ${DE_KOPIA_BLOCK_HASH:-BLAKE3-256-128} \
      --content-cache-size-mb ${DE_KOPIA_CACHE_SIZE:-5000} \
      --enable-actions ${DE_KOPIA_MAX_DOWNLOAD_SPEED} ${DE_KOPIA_MAX_UPLOAD_SPEED} \
      --override-username ${DE_KOPIA_USERNAME:-kopia} \
      --override-hostname ${DE_KOPIA_HOSTNAME:-kopiaserver} \
      --password ${DE_KOPIA_REPOSITORY_PASSWORD} \
      --container ${DE_AZURE_CONTAINER} ${DE_AZURE_SAS_TOKEN} \
      --storage-domain ${DE_AZURE_STORAGE_DOMAIN}
  else
    echo "connect to Azure repository"
    kopia repository connect azure \
      --content-cache-size-mb ${DE_KOPIA_CACHE_SIZE:-5000} \
      --enable-actions ${DE_KOPIA_MAX_DOWNLOAD_SPEED} ${DE_KOPIA_MAX_UPLOAD_SPEED} \
      --override-username ${DE_KOPIA_USERNAME:-kopia} \
      --override-hostname ${DE_KOPIA_HOSTNAME:-kopiaserver} \
      --password ${DE_KOPIA_REPOSITORY_PASSWORD} \
      --container ${DE_AZURE_CONTAINER} ${DE_AZURE_SAS_TOKEN} \
      --storage-domain ${DE_AZURE_STORAGE_DOMAIN}
  fi
fi

# https://kopia.io/docs/reference/command-line/common/repository-create-b2/
if [ ! -z "${DE_B2_KEY}" ]; then
  if [ ! -z "${DE_KOPIA_FIRST_BOOT}" ]; then
    echo "create Backblaze B2 repository"
    kopia repository create b2 \
      --block-hash ${DE_KOPIA_BLOCK_HASH:-BLAKE3-256-128} \
      --content-cache-size-mb ${DE_KOPIA_CACHE_SIZE:-5000} \
      --enable-actions ${DE_KOPIA_MAX_DOWNLOAD_SPEED} ${DE_KOPIA_MAX_UPLOAD_SPEED} \
      --override-username ${DE_KOPIA_USERNAME:-kopia} \
      --override-hostname ${DE_KOPIA_HOSTNAME:-kopiaserver} \
      --password ${DE_KOPIA_REPOSITORY_PASSWORD} \
      --bucket ${DE_B2_BUCKET}
  else
    echo "connect to Backblaze B2 repository"
    kopia repository connect b2 \
      --content-cache-size-mb ${DE_KOPIA_CACHE_SIZE:-5000} \
      --enable-actions ${DE_KOPIA_MAX_DOWNLOAD_SPEED} ${DE_KOPIA_MAX_UPLOAD_SPEED} \
      --override-username ${DE_KOPIA_USERNAME:-kopia} \
      --override-hostname ${DE_KOPIA_HOSTNAME:-kopiaserver} \
      --password ${DE_KOPIA_REPOSITORY_PASSWORD} \
      --bucket ${DE_B2_BUCKET}
  fi
fi

# https://kopia.io/docs/reference/command-line/common/repository-create-s3/
if [ ! -z "${DE_AWS_SECRET_ACCESS_KEY}" ]; then
  if [ ! -z "${DE_KOPIA_FIRST_BOOT}" ]; then
    echo "create S3 repository"
    kopia repository create s3 \
      --block-hash ${DE_KOPIA_BLOCK_HASH:-BLAKE3-256-128} \
      --content-cache-size-mb ${DE_KOPIA_CACHE_SIZE:-5000} \
      --enable-actions ${DE_KOPIA_MAX_DOWNLOAD_SPEED} ${DE_KOPIA_MAX_UPLOAD_SPEED} \
      --override-username ${DE_KOPIA_USERNAME:-kopia} \
      --override-hostname ${DE_KOPIA_HOSTNAME:-kopiaserver} \
      --password ${DE_KOPIA_REPOSITORY_PASSWORD} \
      --bucket ${DE_S3_BUCKET} \
      --endpoint ${DE_S3_ENDPOINT} ${DE_S3_REGION}
  else
    echo "connect to S3 repository"
    kopia repository connect s3 \
      --content-cache-size-mb ${DE_KOPIA_CACHE_SIZE:-5000} \
      --enable-actions ${DE_KOPIA_MAX_DOWNLOAD_SPEED} ${DE_KOPIA_MAX_UPLOAD_SPEED} \
      --override-username ${DE_KOPIA_USERNAME:-kopia} \
      --override-hostname ${DE_KOPIA_HOSTNAME:-kopiaserver} \
      --password ${DE_KOPIA_REPOSITORY_PASSWORD} \
      --bucket ${DE_S3_BUCKET} \
      --endpoint ${DE_S3_ENDPOINT} ${DE_S3_REGION}
  fi
fi

# https://kopia.io/docs/reference/command-line/common/repository-create-webdav/
if [ ! -z "${DE_WEBDAV_PASSWORD}" ]; then
  if [ ! -z "${DE_KOPIA_FIRST_BOOT}" ]; then
    echo "create WebDAV repository"
    kopia repository create webdav \
      --block-hash ${DE_KOPIA_BLOCK_HASH:-BLAKE3-256-128} \
      --content-cache-size-mb ${DE_KOPIA_CACHE_SIZE:-5000} \
      --enable-actions ${DE_KOPIA_MAX_DOWNLOAD_SPEED} ${DE_KOPIA_MAX_UPLOAD_SPEED} \
      --override-username ${DE_KOPIA_USERNAME:-kopia} \
      --override-hostname ${DE_KOPIA_HOSTNAME:-kopiaserver} \
      --password ${DE_KOPIA_REPOSITORY_PASSWORD} \
      --url ${DE_WEBDAV_URL} ${DE_WEBDAV_FLAT}
  else
    echo "connect to WebDAV repository"
    kopia repository connect webdav \
      --content-cache-size-mb ${DE_KOPIA_CACHE_SIZE:-5000} \
      --enable-actions ${DE_KOPIA_MAX_DOWNLOAD_SPEED} ${DE_KOPIA_MAX_UPLOAD_SPEED} \
      --override-username ${DE_KOPIA_USERNAME:-kopia} \
      --override-hostname ${DE_KOPIA_HOSTNAME:-kopiaserver} \
      --password ${DE_KOPIA_REPOSITORY_PASSWORD} \
      --url ${DE_WEBDAV_URL} ${DE_WEBDAV_FLAT}
  fi
fi

if [ ! -z "${DE_KOPIA_FIRST_BOOT}" ]; then
  kopia policy set --global \
    --compression ${DE_KOPIA_COMPRESSION} \
    --keep-annual 3 --keep-daily 7 --keep-hourly 0 --keep-latest 0 --keep-monthly 12 \
    --keep-weekly 4 ${DE_KOPIA_MAX_FILE_SIZE} --add-dot-ignore .kopiaignore

  while IFS=',' read -ra COMP; do
    for i in "${COMP[@]}"; do
      kopia policy set --global --add-never-compress $i
    done
  done <<<"$DE_KOPIA_NEVER_COMPRESS"
fi

# -------------------------------------------------------------------------------
# Client related

if [ ! -z "${DE_KOPIA_USERS}" ]; then

  kopia repository connect from-config \
    --file /app/config/repository.config \
    --override-username ${DE_KOPIA_USERNAME:-kopia} \
    --override-hostname ${DE_KOPIA_HOSTNAME:-kopiaserver} \
    --password ${DE_KOPIA_REPOSITORY_PASSWORD}

  while IFS=',' read -ra USERS; do
    for i in "${USERS[@]}"; do
      echo "$i --user-password" $(tr </dev/urandom -cd 'a-zA-Z0-9' | head -c 32) >>/app/config/userlist.txt
    done
  done <<<"$DE_KOPIA_USERS"

  if [ ! -z "${DE_KOPIA_UPDATE_USERS}" ]; then
    echo "Updating user passwords"
    while read user; do
      kopia server users set $user
    done </app/config/userlist.txt
  else
    echo "Adding users"
    while read user; do
      kopia server users add $user
    done </app/config/userlist.txt
  fi
fi

if [ ! -z "${DE_KOPIA_CLIENT}" ]; then
  echo "connect to repository"
  kopia repository connect server --url ${DE_KOPIA_SERVER_URL:-https://kopia:51515} \
    --override-username ${DE_KOPIA_USERNAME:-kopia} \
    --override-hostname ${DE_KOPIA_HOSTNAME:-kopia} \
    --enable-actions \
    --server-cert-fingerprint ${DE_KOPIA_SERVER_FINGERPRINT}
fi

if [ ! -z "${DE_KOPIA_SNAPSHOT_TIME}" ]; then
  echo "setting snapshot time"
  kopia policy set \
    ${DE_KOPIA_USERNAME:-kopia}@${DE_KOPIA_HOSTNAME:-kopia}:/app/data \
    --snapshot-time ${DE_KOPIA_SNAPSHOT_TIME}
fi

if [ ! -z "${HEALTHCHECKS_START_URL}" ]; then
  echo "create /app/start.sh"
  cat >"/app/start.sh" <<'EOF'
#!/bin/sh

set -e

curl -L -m 10 --retry 3 --silent --output /dev/null $HEALTHCHECKS_START_URL
EOF
  chmod +x /app/start.sh

  kopia policy set \
    ${DE_KOPIA_USERNAME:-kopia}@${DE_KOPIA_HOSTNAME:-kopia}:/app/data \
    --action-command-mode ${DE_KOPIA_ACTION_MODE:-essential} \
    --before-snapshot-root-action /app/start.sh
fi

if [ ! -z "${HEALTHCHECKS_SUCCESS_URL}" ]; then
  echo "create /app/start.sh"
  cat >"/app/success.sh" <<'EOF'
#!/bin/sh

set -e

echo "KOPIA_SNAPSHOT_ID:$KOPIA_SNAPSHOT_ID" >&2

kopia snapshot list --max-results 1 --no-retention >&2

if [ ! -z "$DE_KOPIA_SNAPSHOT_VERIFY" ]; then
kopia snapshot verify --verify-files-percent $DE_KOPIA_SNAPSHOT_VERIFY >&2
fi

curl -L -m 10 --retry 3 --silent --output /dev/null $HEALTHCHECKS_SUCCESS_URL

echo "" >&2
EOF
  chmod +x /app/success.sh

  kopia policy set \
    ${DE_KOPIA_USERNAME:-kopia}@${DE_KOPIA_HOSTNAME:-kopia}:/app/data \
    --action-command-mode ${DE_KOPIA_ACTION_MODE:-essential} \
    --after-snapshot-root-action /app/success.sh
fi

if [ -z "$1" ]; then
  if [ ! -z "${DE_KOPIA_CLIENT}" ]; then
    echo "running in client mode"
    exec kopia server start --insecure --enable-actions --timezone ${TIME_ZONE:-Etc/UTC}
  else
    echo "running as repository server"
    exec kopia server start --tls-cert-file /run/secrets/kopia.cert --tls-key-file /run/secrets/kopia.key --enable-actions --timezone ${TIME_ZONE:-Etc/UTC} --metrics-listen-addr https://0.0.0.0:51515 --address https://0.0.0.0:51515
  fi
else
  exec "$@"
fi
