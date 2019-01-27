FROM alpine:3.8

ARG DOCKER_VERSION="18.06.1-ce"
ARG AWS_CLI_VERSION="1.16.84"
ARG S3CMD_VERSION="2.0.2"
ARG GRACEFUL_STOP_TIMEOUT_SEC=120

ARG DOWNLOAD_URL="https://download.docker.com/linux/static/stable/x86_64/docker-$DOCKER_VERSION.tgz"
ARG INSTALL_DIR
ARG RCONPWD

ENV RCONPWD ${RCONPWD}
ENV INSTALL_DIR ${INSTALL_DIR}
ENV APP_NAME Minecraft Server Ctrl
ENV GRACEFUL_STOP_TIMEOUT_SEC ${GRACEFUL_STOP_TIMEOUT_SEC}
ENV PATH ${INSTALL_DIR}/bin:$PATH

# AWS environment.


# Add community repository.
RUN echo "http://dl-cdn.alpinelinux.org/alpine/latest-stable/community" >> /etc/apk/repositories
RUN apk update

# Install curl.
RUN apk --update add curl

# Install docker client.
RUN mkdir -p /tmp/download \
    && curl -L $DOWNLOAD_URL | tar -xz -C /tmp/download \
    && mv /tmp/download/docker/docker /usr/local/bin/ \
    && rm -rf /tmp/download \
    && rm -rf /var/cache/apk/*

# Install python
RUN apk -v --update add \
        python \
        py-pip \
        groff \
        less \
        mailcap \
        && \
    pip install --upgrade \
        awscli==${AWS_CLI_VERSION} \
        s3cmd==${S3CMD_VERSION} \
	python-magic \
	docker-compose 

# Remove apk cache files.
RUN rm /var/cache/apk/*

ADD rootfs /

RUN echo -e  "\<install_dir\> is ${INSTALL_DIR} \n " \
"Default rcon password is ${RCONPWD}. \n" >> /image_info.txt

VOLUME ["${INSTALL_DIR}/map_data", "${INSTALL_DIR}/map_logs"]

EXPOSE 25565 25575

CMD ["/bin/cat", "/image_info.txt"]
