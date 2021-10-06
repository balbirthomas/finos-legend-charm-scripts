## Private Hosted Gitlab using Docker Compose

It is possible to use Finos Legend charms can be used in conjunction
with a private hosted Gitlab. For this purpose the deployed Legend
charms need to be provided with the TLS certificates that Gitlab
uses. An example of deploying such a private hosted Gitlab, deployed
using docker Compose is shown below. The docker compose file used
for this is as follows
```
version: '3.6'
services:
  gitlab:
    image: 'gitlab/gitlab-ee:latest'
    restart: always
    hostname: 'gitlab'
    domainname: 'gitlab.local'
    container_name: 'gitlab'
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'https://gitlab.local:443'
        gitlab_rails['initial_root_password'] = '${FINOS_GITLAB_PASSWORD:?no gitlab password set}'
        gitlab_rails['gitlab_shell_ssh_port'] = 2224
        gitlab_rails['lfs_enabled'] = true
        nginx['listen_port'] = 443
        nginx['ssl_certificate'] = '/etc/gitlab/ssl/gitlab.local.crt'
        nginx['ssl_certificate_key'] = '/etc/gitlab/ssl/gitlab.local.key'
        letsencrypt['enable'] = false
    ports:
      - '443:443'
      - '2224:2224'
    volumes:
      - '${GITLAB_HOME:?no gitlab home set}/config:/etc/gitlab'
      - '${GITLAB_HOME:?no gitlab home set}/logs:/var/log/gitlab'
      - '${GITLAB_HOME:?no gitlab home set}/data:/var/opt/gitlab'
      - './certs:/etc/gitlab/ssl'
    networks:
      legend:
        ipv4_address: 172.18.0.2
networks:
  legend:
    ipam:
      driver: default
      config:
        - subnet: 172.18.0.0/16

```

Prior to deploying Gitlab using this docker compose file two
environment variables need to be set

1. `GITLAB_HOME` : This is the folder location under which Gitlab will
   store all its data.
2. `FINOS_GITLAB_PASSWORD` : This is the root password for Gitlab. 

Also note that this docker compose file sets a static IP address for
Gitlab because the IP address is used in generating TLS certificates
for Gitlab. This IP subnet and address may be changed to suit your
own deployment. Generation of the TLS certificate can now be done
using a OpenSSL configuration file (`cert.cnf`) as follows

```
[ req ]
default_bits                  = 2048
distinguished_name            = req_distinguished_name
req_extensions                = req_ext
[ req_distinguished_name ]
countryName                   = US
stateOrProvinceName           = NY
localityName                  = NY
organizationName              = XX
commonName                    = gitlab.local
[ req_ext ]
subjectAltName                = @alt_names
[alt_names]
DNS.1=gitlab.local
IP.1=172.18.0.2
```

Note that the OpenSSL config file uses the same IP as in the docker
compose file to specify Subject Alternative Names. Using this config
file TLS certificates may be generated using the following command
line

```
$ openssl req -newkey rsa:2048 -nodes -keyout "${HOST_KEY_FILE}" -x509 -days 365 -out "${HOST_CERT_FILE}" \
	-config "cert.cnf" -extensions req_ext -subj "/C=US/ST=NY/L=NY/O=XX/CN=${HOST_DNS_NAME}"
$ openssl x509 -in "${HOST_CERT_FILE}" -outform der -out "${HOST_DER_FILE}"
```

This command line generates self signed certificates.  Assuming the
docker compose file (above) is in your current directory and the
certificates are in a subdirectory `certs` in the same directory, a
Gitlab instance may be launched using the standard command line such
as `docker-compose up -d`.

