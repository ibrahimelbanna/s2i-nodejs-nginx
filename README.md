# S2I: Node.js / NGINX

This is an updated fork of 
[jshmrtn/s2i-nodejs-nginx](https://github.com/jshmrtn/s2i-nodejs-nginx). Full
credit to them for creating this 🤘

## Node.js Releases / Versions

- 10
- 12
- 14

Minor versions cannot be specified. The tag will always point to the latest
release for that major version.

## Usage

OpenShift allows you to quickly start a build using the web console, or the CLI.

With the [`oc` command-line tool](https://github.com/openshift/origin/releases)
you can bundle a static project (based on a Node.js build setup, for example
Webpack) into a centos7 image running only NGINX:

```bash
oc new-app quay.io/evanshortiss/s2i-nodejs-nginx:RELEASE~REPO_URL
```

## Configuration

### nginx.conf

You can add your custom `nginx.conf` to the container. While assembling, the builder looks for a nginx.conf file in your projects `.s2i/nginx/` directory. If there is a `nginx.conf` present at `.s2i/nginx/nginx.conf`, it will copy all contents of the `.s2i/nginx/` directory and put it into the target images `/opt/app-root/etc` directory. There the custom nginx.conf file will be used.

```bash
if [[ -f .s2i/nginx/nginx.conf ]]; then
  echo "---> Installing custom NGINX configuration..."
  cp -Rf .s2i/nginx/. /opt/app-root/etc/
else
  echo "---> Installing stock NGINX configuration..."
  cp -Rf /opt/app-root/etc/nginx.default.conf /opt/app-root/etc/nginx.conf
fi
```

### nginx.conf includes

You can include files in your custom configuration. This is useful if you have many configuration files. If you provide the builder with a custom nginx.conf file in your projects `.s2i/nginx/` directory, all other files inside `.s2i/nginx/` will be copied along as well. So you could for example include a file with mime types in your custom nginx.conf. Add the file `.s2i/nginx/mime.types` to your project and include it like this:

```
include       /opt/app-root/etc/mime.types;
```

### Basic Auth

The builder can add basic auth to the container for you. All you need to do is
to set some environment variables.

*Note: These must be set on the OpenShift BuildConfig*

* BASICAUTH_USERNAME - the username used for basic auth.
* BASICAUTH_PASSWORD - the password used for basic auth.
* BASICAUTH_TITLE - the title used for basic auth.
