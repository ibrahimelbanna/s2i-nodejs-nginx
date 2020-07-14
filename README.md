# S2I: Node.js / NGINX

This is an updated fork of 
[jshmrtn/s2i-nodejs-nginx](https://github.com/jshmrtn/s2i-nodejs-nginx), that
builds on their incredible work - thank you jshmrtn! 🤘

## What Does it Do?

When used in conjunction with [s2i (source-to-image)](https://github.com/openshift/source-to-image#installation),
it bundles the source code for a webapp that is built using Node.js tools, and
produces a runnable container image that serves the content using NGINX.

The process is illustrated in the diagram below:

![How it Works](diagram.png "How it Works")

## Supported Node.js Versions

- 10
- 12
- 14

Minor versions cannot be specified. The tag will always point to the latest
release for that major version.

## Usage

Note that the web application being built using this builder must:

1. Contain a `build` entry in the `scripts` section of the *package.json*
1. The `build` script must produce a *dist/* folder in the root of the repository (it can be added to *.gitignore*)
1. An *index.html* must be at the root of the *dist/* folder
1. Other static assets must be included in the *dist/* 

A sample application that satisfies these requirements can be found [here](https://github.com/evanshortiss/s2i-nodejs-nginx-example).

### Source to Image (s2i) CLI

You need to install [s2i](https://github.com/openshift/source-to-image#installation)
and [Docker](https://docs.docker.com/get-docker/) before running the `s2i build`
command below to generate a container image.

```bash
# Node.js version to use for building the application (does not support minor versions)
export NODE_VER=14

# The repository containing the application you'd like to build
export REPO_URL=https://github.com/evanshortiss/s2i-nodejs-nginx-example

# Name for the resulting image tag
export OUTPUT_IMAGE_NAME=nginx-webapp-runner

s2i build $REPO_URL quay.io/evanshortiss/s2i-nodejs-nginx:$NODE_VER $OUTPUT_IMAGE_NAME
```

This will produce a container named `nginx-webapp-runner` that can be started
via `docker run -p 8080:8080 nginx-webapp-runner`.

### OpenShift CLI

With the [OpenShift CLI (`oc`)](https://docs.openshift.com/container-platform/4.4/cli_reference/openshift_cli/getting-started-cli.html)
you can deploy the static site using the following command:

```bash
# Node.js version to use for building the application (does not support minor versions)
export NODE_VER=14

# The repository containing the application you'd like to build
export REPO_URL=https://github.com/evanshortiss/s2i-nodejs-nginx-example

oc new-app quay.io/evanshortiss/s2i-nodejs-nginx:$NODE_VER~$REPO_URL
```

This will create a **BuildConfig** and the other necessary API Objects on
your OpenShift instance to build the application via source-to-image and deploy
it.

## Configuration

### Defaults

The out of the box configuration does the following:

* Listens on port 8080
* Serves *dist/index.html* for the `/` route
* Applies GZIP compression to text-based assets larger than 1000 bytes
* Logs at INFO level to stdout
* Includes NGINX default mime type mappings

### Customising nginx.conf

You can add your custom `nginx.conf` to the container. While assembling, the builder looks for a nginx.conf file in your project `.s2i/nginx` directory. If there is a `nginx.conf` present at `.s2i/nginx/nginx.conf`, it will copy all contents of the `.s2i/nginx/` directory and put it into the target images `/opt/app-root/etc` directory. There the custom nginx.conf file will be used.

### nginx.conf includes

You can include files in your custom configuration. This is useful if you have many configuration files. If you provide the builder with a custom nginx.conf file in your projects `.s2i/nginx/` directory, all other files inside `.s2i/nginx/` will be copied along as well. So you could for example include a file with mime types in your custom nginx.conf. Add the file `.s2i/nginx/mime.types` to your project and include it like this:

```
include /opt/app-root/etc/mime.types;
```

### Basic Auth

The builder can add basic auth to the container for you. All you need to do is
to set some environment variables.

*Note: These must be set on the OpenShift BuildConfig*

* `BASICAUTH_USERNAME` - the username used for basic auth.
* `BASICAUTH_PASSWORD` - the password used for basic auth.
* `BASICAUTH_TITLE` - the title used for basic auth.
