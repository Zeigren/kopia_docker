# Docker Stack For [Kopia](https://kopia.io/)

![Docker Image Size (latest)](https://img.shields.io/docker/image-size/zeigren/kopia/latest)
![Docker Pulls](https://img.shields.io/docker/pulls/zeigren/kopia)

## Tags

Tag is the version of Kopia

- latest
- v0.8.4

## Links

### [Docker Hub](https://hub.docker.com/r/zeigren/kopia)

### [GitHub](https://github.com/Zeigren/kopia_docker)

## Usage

Use [Docker Swarm](https://docs.docker.com/engine/swarm/) to deploy. There are examples for using Traefik for SSL termination.

This is designed to be used as a [Repository Server](https://kopia.io/docs/repository-server/) with clients that connect to it, but you can use the container on its own. The clients can be remote or they could be other docker stacks, the container uses like 15MB of RAM at rest so running a bunch is easy.

The Repository Server web interface can be exposed to the internet or accessed over your local network and can be used for managing the connected clients, or you can attach to the Repository Server container and run commands. The clients can have their web interface exposed but I wouldn't really recommend it.

Much of the process of creating repositories, users, and basic policies has been automated to try and make it easier to get setup, especially if you're going to connect a lot of clients.

## Configuration

Configuration consists of environment variables in the `.yml` files.

### Traefik Configuration

#### Generate Kopia backend cert

The Kopia server communicates with traefik and the clients over HTTPS in order to proxy gRPC, as such you'll need to create a backend certificate for it.

- kopia.cert = The SSL certificate for the backend
- kopia.key = The SSL key for the backend

`openssl req -x509 -nodes -days 14600 -newkey rsa:2048 -keyout ./kopia.key -out ./kopia.cert`

Get the SHA256 value since that's how the clients check the servers certificate.

`openssl x509 -in ./kopia.cert -noout -fingerprint -sha256 | sed 's/://g' | cut -f 2 -d =`

### [Docker Swarm](https://docs.docker.com/engine/swarm/)

I personally use this with [Traefik](https://traefik.io/) as a reverse proxy, I've included an example `traefik.yml`.

You'll need to create the appropriate [Docker Secrets](https://docs.docker.com/engine/swarm/secrets/).

Run with `docker stack deploy --compose-file docker-swarm.yml kopia`

### Environment Variables

Any that begin with `DE_` can use Docker secrets. Look at the documentation for more info on some of the environment variables [https://kopia.io/docs/](https://kopia.io/docs/)

#### All

- `DE_KOPIA_HOSTNAME` - Set the hostname used to connect to the Repository Server
- `DE_KOPIA_USERNAME` - Set the username used to connect to the Repository Server
- `KOPIA_SERVER_USERNAME`  - Set the HTTP auth username for the server
- `DE_KOPIA_SERVER_PASSWORD` - Set the HTTP auth password
- `TIME_ZONE`

#### Repository Server

- `DE_KOPIA_USERS` - Add or update users to the Repository Server
  - A comma seperated list of users with the format `DE_KOPIA_USERNAME@DE_KOPIA_HOSTNAME,user2@hostname`
  - A 32 character password is randomly generated for each user and saved to `/app/config/userlist.txt`, connect to the container and back this up and then delete the file
  - Set the environment variable `DE_KOPIA_UPDATE_USERS` to true to update users with new passwords instead of adding them
  - Remove the environment variable after each use
- `DE_KOPIA_BLOCK_HASH` - Set the repository block hash, if not set on first run it'll run a benchmark and set it to the best result
- `DE_KOPIA_COMPRESSION` - Set the default compression type for the global policy, if not set on first run it'll run a benchmark and set it to the best result
- `DE_KOPIA_FIRST_BOOT` - Set to true on first boot to setup the repository
- `DE_KOPIA_MAX_DOWNLOAD_SPEED`
- `DE_KOPIA_MAX_UPLOAD_SPEED`
- `DE_KOPIA_MAX_FILE_SIZE`
- `DE_KOPIA_NEVER_COMPRESS` - a comma seperated list of file extensions that won't be compressed. The default is `7z,rar,zip,bz,bz2,gz,lzma,lzo,tbz2,tgz,txz,xz,zipx`
- `DE_KOPIA_REPOSITORY_PASSWORD`

#### Repository Server Automated Setup

##### [S3](https://kopia.io/docs/reference/command-line/common/repository-create-s3/)

- `DE_AWS_SECRET_ACCESS_KEY`
- `AWS_ACCESS_KEY_ID`
- `DE_AWS_SESSION_TOKEN`
- `DE_S3_BUCKET`
- `DE_S3_ENDPOINT`
- `DE_S3_REGION` - don't use for S3 compatible

##### [Azure](https://kopia.io/docs/reference/command-line/common/repository-create-azure/)

- `AZURE_STORAGE_ACCOUNT`
- `DE_AZURE_CONTAINER`
- `DE_AZURE_SAS_TOKEN`
- `DE_AZURE_STORAGE_DOMAIN`
- `DE_AZURE_STORAGE_KEY`

##### [Backblaze B2](https://kopia.io/docs/reference/command-line/common/repository-create-b2/)

- `DE_B2_BUCKET`
- `B2_KEY_ID`
- `DE_B2_KEY`

##### [Webdav](https://kopia.io/docs/reference/command-line/common/repository-create-webdav/)

- `KOPIA_WEBDAV_USERNAME`
- `DE_WEBDAV_FLAT`
- `DE_WEBDAV_PASSWORD`
- `DE_WEBDAV_URL`

#### Client

- `DE_KOPIA_ACTION_MODE` - [https://kopia.io/docs/advanced/actions/](https://kopia.io/docs/advanced/actions/)
- `DE_KOPIA_CLIENT` - set to true for client mode
- `DE_KOPIA_CLIENT_PASSWORD` - password used to authenticate client with Repository Server
- `DE_KOPIA_SERVER_FINGERPRINT` - SHA256 hash of the Repository Server certificate
- `DE_KOPIA_SERVER_URL` - change the server url to connect to
- `DE_KOPIA_SNAPSHOT_TIME` - Set daily backup schedule time `HH:mm` format, this currently is GMT and is not affected by `TIME_ZONE`
- `HEALTHCHECKS_START_URL` - pings an endpoint with curl before backing up
  - I made a [healthchecks.io](https://github.com/Zeigren/healthchecks-docker) docker stack as well
- `HEALTHCHECKS_SUCCESS_URL` - pings an endpoint with curl on successful back up
  - If using `HEALTHCHECKS_SUCCESS_URL` you can also set `DE_KOPIA_SNAPSHOT_VERIFY` to a number between `1-100` to verify that percentage of the snapshot

#### Other Environment Variables

- `KOPIA_DIFF` - Displays differences between two repository objects (files or directories)
- `KOPIA_RESTORE_CONSISTENT_ATTRIBUTES` - When multiple snapshots match, fail if they have inconsistent attributes
- `KOPIA_SNAPSHOT_FAIL_FAST` - Fail fast when creating snapshot
- `KOPIA_TRACE_FS` - Enables tracing of local filesystem operations
- `KOPIA_LOG_DIR_MAX_FILES` - Maximum number of log files to retain
- `KOPIA_LOG_DIR_MAX_AGE` - Maximum age of log files to retain
- `KOPIA_CONTENT_LOG_DIR_MAX_FILES` - Maximum number of content log files to retain
- `KOPIA_CONTENT_LOG_DIR_MAX_AGE` - Maximum age of content log files to retain
- `DE_KOPIA_AUTH_COOKIE_SIGNING_KEY`
- `DE_KOPIA_CACHE_SIZE` - Default is 5000MB
- `KOPIA_CACHE_DIRECTORY`
- `KOPIA_CHECK_FOR_UPDATES`
- `KOPIA_CONFIG_PATH`
- `KOPIA_LOG_DIR`
- `KOPIA_PERSIST_CREDENTIALS_ON_CONNECT`
