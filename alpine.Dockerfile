# This Dockerfile is derived from https://github.com/bitwalker

# This node version is passed via --build-arg, but will be replaced
# after the FROM statement with the version specified in the image
ARG NODE_VERSION

FROM node:${NODE_VERSION}-alpine

# need to declare these for use *after* the FROM statement
# NODE_VERSION is set in the alpine image already 
ARG NGINX_VERSION
ARG APK_REPO

EXPOSE 8080

USER root

ENV NPM_CONFIG_LOGLEVEL=info \
    NPM_CONFIG_PREFIX=$HOME/.npm-global \
    PATH=$HOME/node_modules/.bin/:$HOME/.npm-global/bin/:$PATH \
    GIT_VERSION=master

LABEL io.k8s.description="Platform for building and running static sites with Node.js and NGINX." \
      io.k8s.display-name="build-nodejs-nginx Node.js v$NODE_VERSION" \
      io.openshift.s2i.scripts-url=image:///usr/libexec/s2i \
      io.s2i.scripts-url=image:///usr/libexec/s2i \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="builder,nodejs,nodejs$NODE_VERSION,nginx" \
      com.redhat.deployments-dir="${APP_ROOT}/src" \
      io.origin.builder-version="$GIT_VERSION" \
      name="evanshortiss/s2i-nodejs-nginx" \
      maintainer="Evan Shortiss <evanshortiss@gmail.com>" \
      version="$NODE_VERSION"


ENV STI_SCRIPTS_PATH=/usr/libexec/s2i \
    HOME=/opt/app-root/src

RUN echo "Using Node.js v${NODE_VERSION} and NGINX v${NGINX_VERSION}"

RUN mkdir -p ${HOME} && \
    mkdir -p /usr/libexec/s2i && \
    adduser -s /bin/sh -u 1001 -G root -h ${HOME} -S -D default && \
    chown -R 1001:0 /opt/app-root && \
    apk -U upgrade && \
    apk add --no-cache --update bash tar && \
    echo "Installing NGINX ${NGINX_VERSION}" && \
    apk add --no-cache nginx --repository=${APK_REPO} nginx~=${NGINX_VERSION} && \
    rm -rf /var/cache/apk/*

COPY ./s2i/bin/ $STI_SCRIPTS_PATH

# Add nginx default conf from this project, and setup mime.types
ADD ./contrib/nginx.default.conf /opt/app-root/etc/nginx.default.conf
RUN cp /etc/nginx/mime.types /opt/app-root/etc/mime.types

# Need this for to allow nginx to create a pid
RUN mkdir -p /run/nginx

USER 1001

CMD $STI_SCRIPTS_PATH/usage
