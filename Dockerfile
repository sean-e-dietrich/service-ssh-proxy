FROM farmer1992/sshpiperd:latest

LABEL maintainer="Docksal <developer@docksal.io>"

RUN set -xe; \
	apk add --update --no-cache \
		bash \
		curl \
		sudo \
		supervisor \
    openssh-keygen \
		openssh-client \
    sshpass \
	; \
	rm -rf /var/cache/apk/*

ARG DOCKER_VERSION=18.06.1-ce

# Install docker client binary (if not mounting binary from host)
RUN set -xe; \
	curl -sSL -O "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz"; \
	tar zxf docker-$DOCKER_VERSION.tgz; \
	mv docker/docker /usr/local/bin ; \
	rm -rf docker*

COPY conf/sudoers /etc/sudoers
# Override the main supervisord config file, since some parameters are not overridable via an include
# See https://github.com/Supervisor/supervisor/issues/962
COPY conf/supervisord.conf /etc/supervisord.conf
COPY conf/crontab /var/spool/cron/crontabs/root
COPY bin /usr/local/bin
COPY healthcheck.sh /opt/healthcheck.sh
COPY conf/sshpiperd.ini /etc/sshpiperd.ini
COPY banner.txt /banner.txt
COPY authorized_keys /authorized_keys

# Fix permissions
RUN chmod 0440 /etc/sudoers

ENV \
  SSHPIPERD_UPSTREAM_WORKINGDIR=/var/sshpiper \
	SSHPASS=docker

# Generate SSH Key
RUN ssh-keygen \
  -t rsa \
	-b 4096 \
  -f /etc/ssh/ssh_host_rsa_key \
  -N ""

# Starter script
ENTRYPOINT ["docker-entrypoint.sh"]

# By default, launch supervisord to keep the container running.
CMD ["supervisord"]

# Health check script
HEALTHCHECK --interval=5s --timeout=1s --retries=3 CMD ["/opt/healthcheck.sh"]
