FROM alpine:3.13

ARG DOCKER_VERSION="19.03.14"
ARG AWS_CLI_VERSION="1.16.84"
ARG S3CMD_VERSION="2.0.2"

ARG DOWNLOAD_URL="https://download.docker.com/linux/static/stable/x86_64/docker-$DOCKER_VERSION.tgz"
ARG INSTALL_DIR
ARG RCONPWD

ENV RCONPWD ${RCONPWD}
ENV INSTALL_DIR ${INSTALL_DIR}
ENV APP_NAME Minecraft Server Ctrl
ENV PATH ${INSTALL_DIR}/bin:$PATH

RUN apk update

# AWS environment.
RUN apk add aws-cli
RUN apk add docker-compose
RUN apk add docker

RUN apk add bash
RUN apk add curl

RUN apk add py3-pip
RUN python3 -m pip install boto3==1.19.4
RUN python3 -m pip install toml==0.10.2

# Add community repository.
#RUN echo "http://dl-cdn.alpinelinux.org/alpine/latest-stable/community" >> /etc/apk/repositories
# RUN apk update

# Install bash.
# RUN apk add bash

# Install curl.
#RUN apk --update add curl

# Install docker with docker client.
#RUN apk --update add docker docker-compose

# Install docker client.
#RUN mkdir -p /tmp/download \
#    && curl -L $DOWNLOAD_URL | tar -xz -C /tmp/download \
#    && mv /tmp/download/docker/docker /usr/local/bin/ \
#    && rm -rf /tmp/download \
#    && rm -rf /var/cache/apk/*

# Install aws cli.
#RUN apk --update add aws-cli

# Install python 2
#RUN apk -v --update add \
#        python3 \
#        py3-pip \
#        groff \
#        less \
#        mailcap
#RUN python3 -m ensurepip
#RUN pip3 install --upgrade pip setuptools
#RUN pip install --upgrade python-magic
#RUN pip install --upgrade boto3
#RUN pip install --upgrade awscli
#RUN pip install --upgrade s3cmd
#RUN pip install --upgrade toml
##RUN apk add python-dev libffi-dev openssl-dev gcc libc-dev make
#RUN pip install --upgrade docker-compose 

# Install python3
#RUN apk -v --update add python3
#RUN python3 -m pip install --upgrade pip
#RUN python3 -m pip install --upgrade toml awscli boto3

#        awscli==${AWS_CLI_VERSION} \
#        s3cmd==${S3CMD_VERSION} \

# Remove apk cache files.
RUN rm /var/cache/apk/*

ADD rootfs /

RUN echo -e  "\<install_dir\> is ${INSTALL_DIR} \n " \
"Default rcon password is ${RCONPWD}. \n" >> /image_info.txt

VOLUME ["${INSTALL_DIR}/map_data", "${INSTALL_DIR}/map_logs"]

# EXPOSE 25565 25575

CMD ["/bin/cat", "/image_info.txt"]
