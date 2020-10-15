# This Dockerfile is derived from https://github.com/bitwalker/s2i-alpine-base

# This node version is passed via --build-arg, but will be replaced
# after the FROM statement with the version specified in the image
ARG NODE_VERSION

FROM node:${NODE_VERSION}-alpine

# Need to declare the build args for use *after* the FROM statement
# NODE_VERSION is set in the alpine image already so we don't redeclare it
ARG NGINX_VERSION
ARG APK_REPO
ARG NODE_VERSION

EXPOSE 8080
EXPOSE 8443

ENV NPM_CONFIG_LOGLEVEL=info \
    GIT_VERSION=master \
    STI_SCRIPTS_PATH=/usr/libexec/s2i \
    HOME=/opt/app-root/src \
    APP_ROOT=/opt/app-root \
    PATH=$HOME/node_modules/.bin/:$HOME/.npm-global/bin/:$PATH

LABEL io.k8s.description="Platform for building and running static sites with Node.js ${NODE_VERSION} and NGINX ${NGINX_VERSION}" \
      io.k8s.display-name="Node.js v$ and NGINX v${NGINX_VERSION}" \
      io.openshift.s2i.scripts-url=image:///usr/libexec/s2i \
      io.s2i.scripts-url=image:///usr/libexec/s2i \
      io.openshift.expose-services="8080:http" \
      io.openshift.expose-services="8443:https" \
      io.openshift.tags="builder,nodejs,nodejs${NODE_VERSION},nginx" \
      com.redhat.deployments-dir="${APP_ROOT}/src" \
      io.origin.builder-version="$GIT_VERSION" \
      name="evanshortiss/s2i-nodejs-nginx" \
      maintainer="Evan Shortiss <evanshortiss@gmail.com>" \
      version="${NODE_VERSION}-nginx${NGINX_VERSION}"

RUN echo "Using Node.js v${NODE_VERSION} and NGINX v${NGINX_VERSION}"

RUN mkdir -p ${HOME} && \
    mkdir -p /usr/libexec/s2i && \
    mkdir ${HOME}/.npm-global && \
    mkdir -p /run/nginx && \ 
    apk -U upgrade && \
    apk add --no-cache --update bash tar && \
    echo "Installing NGINX ${NGINX_VERSION}" && \
    apk add --no-cache nginx --repository=${APK_REPO} nginx~=${NGINX_VERSION} && \
    rm -rf /var/cache/apk/*

COPY ./s2i/bin/ $STI_SCRIPTS_PATH

# Add nginx default conf from this builder project, and setup mime.
# The s2i scripts can overide the nginx.conf using a developer supplied file
ADD ./contrib/nginx.default.conf ${APP_ROOT}/etc/nginx.default.conf
RUN cp /etc/nginx/mime.types ${APP_ROOT}/etc/mime.types

# Create the 1001 user and provide permissions to application
# folders and folders required by NGINX
RUN adduser -s /bin/sh -u 1001 -G root -h ${HOME} -S -D default && \
    chown -R 1001:0 ${APP_ROOT}

RUN chgrp -R 0 /var/lib/nginx/ && chmod -R g+rwX /var/lib/nginx/ && find /var/lib/nginx -type d -exec chmod g+x {} +
RUN chgrp -R 0 /run/nginx && chmod -R g+rwX /run/nginx

USER 1001

WORKDIR ${HOME}

CMD $STI_SCRIPTS_PATH/usage
