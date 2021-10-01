export GITLAB_HOME=${HOME}/tmp/gitlab
CERTS_DIR=certs
HOST_DNS_NAME=gitlab.local
HOST_KEY_FILE=${CERTS_DIR}/${HOST_DNS_NAME}.key
HOST_CERT_FILE=${CERTS_DIR}/${HOST_DNS_NAME}.crt
HOST_DER_FILE=${CERTS_DIR}/${HOST_DNS_NAME}.der
TRUST_STORE_FILE=${CERTS_DIR}/truststore.jks
TRUSTSTORE_PASSWORD=my-secret-password

certs:
	openssl req -newkey rsa:2048 -nodes -keyout "${HOST_KEY_FILE}" -x509 -days 365 -out "${HOST_CERT_FILE}" \
		-config "cert.cnf" -extensions req_ext -subj "/C=US/ST=NY/L=NY/O=XX/CN=${HOST_DNS_NAME}"
	openssl x509 -in "${HOST_CERT_FILE}" -outform der -out "${HOST_DER_FILE}"
	
truststore:
	keytool -import -noprompt -alias "${HOST_DNS_NAME}" -keystore "${TRUST_STORE_FILE}" -file "${HOST_DER_FILE}" \
		-storepass "${TRUSTSTORE_PASSWORD}"

gitlab:
	docker-compose up -d

clean:
	$(RM) certs/*

.PHONY: certs clean gitlab truststore
