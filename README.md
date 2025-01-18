# Nginx Docker Image

This is a simple Docker image for Nginx, created by someone not specialized in configuring Nginx or writing shell scripts, to eliminate the need to configure it over and over again.

This image contains:

- A static Brotli module.
- Support for obtaining SSL certificates with their auto-renewal.
- Support for obtaining Origin CA certificates from Cloudflare with their auto-renewal.
- The ability to substitute environment variables in the Nginx configuration.
- A few basic snippets to configure Nginx.

Important criteria for creating this image were:

- Do not attempt to automate the formation of the configuration file.
- Do not enforce any configuration options.
- Write scripts as simply and clearly as possible.
- Avoid performing complex operations in scripts.

## Contents

- [Installation](#installation)
- [Description](#description)
- [Acknowledgements](#acknowledgements)
- [License](#license)

## Installation

Pull image from Docker Hub:

```sh
docker pull vanyauhalin/nginx
```

... or from GitHub Container registry:

```sh
docker pull ghcr.io/vanyauhalin/nginx
```

## Description

_Description in progress..._

<details>
  <summary>Show <code>ae</code> help message</summary>

```text
Usage: ae [options] <subcommand>
       ae obtain [options] <type>
       ae renew [options]
       ae logs [options]
       ae acme [acme options]

Options:
  -p            Pipes the output to the log file
                (available for 'install', 'obtain', 'schedule', 'trigger' and 'renew' subcommands)

Subcommands:
  help          Shows this help message
  install       Installs acme
  obtain        Obtains certificates
  schedule      Schedules certificate renewal
  trigger       Triggers scheduled operations
  renew         Renews certificates
  logs          Shows the log file
  env           Shows the environment variables
  acme          Runs acme with the specified arguments

Obtain options:
  -g            Guards the existence of certificates
  -s            Skips rendering, testing Nginx configuration and reloading Nginx

Obtain types:
  self          Obtains self-signed certificates
  test          Obtains test certificates
  prod          Obtains production certificates

Renew options:
  -f            Forces the renewal of certificates

Logs options:
  -f            Follows the log file
  -n <lines>    Shows the last n lines of the log file

Environment variables:
  AE_ENABLED             Whether ae is enabled
  AE_CRON                Cron schedule for certificate renewal
  AE_DAYS                Validity period for certificates when obtaining new ones
  AE_DOMAINS             Comma-separated list of domains to obtain certificates for
  AE_EMAIL               Email address to use when obtaining certificates
  AE_KEY_SIZE            Size of the RSA key to be generated
  AE_HEALTHCHECKS_URL    URL to Healthchecks check
```

</details>

<details>
  <summary>Show <code>cf</code> help message</summary>

```txt
Usage: cf [options] <subcommand>
       cf obtain [options]
       cf renew [options]
       cf logs [options]

Options:
  -p            Pipes the output to the log file

Subcommands:
  help          Shows this help message
  obtain        Obtains certificates
  schedule      Schedules certificate renewal
  trigger       Triggers scheduled operations
  renew         Renews certificates
  logs          Shows the log file
  env           Shows the environment variables

Obtain options:
  -g            Guards the existence of certificates
  -s            Skips rendering, testing Nginx configuration and reloading Nginx

Renew options:
  -f            Forces the renewal of certificates

Logs options:
  -f            Follows the log file
  -n <lines>    Shows the last n lines of the log file

Environment variables:
  CF_ENABLED             Whether cf is enabled
  CF_CRON                Cron schedule for certificate renewal
  CF_DAYS                Validity period for certificates when obtaining new ones
                         (can be 7, 30, 90, 365, 730, 1095, 5475)
  CF_DOMAINS             Comma-separated list of domains to obtain certificates for
  CF_TYPE                Type of certificate to obtain
                         (can be origin-rsa, origin-ecc, keyless-certificate)
  CF_API_TOKEN           Cloudflare API token
  CF_HEALTHCHECKS_URL    URL to Healthchecks check
```

</details>

<details>
  <summary>Show <code>ng</code> help message</summary>

```txt
Usage: ng <subcommand>

Subcommands:
  help          Shows this help message
  render        Renders the Nginx config from the template

Environment variables:
  NG_ENABLED             Whether ng is enabled
```

</details>

<details>
  <summary>Show mentioned files and directories in the tree format</summary>

```txt
├─ etc
│  ├─ acme
│  │  └─ ***
│  ├─ cloudflare
│  │  └─ ***
│  └─ nginx
│     ├─ snippets
│     │  ├─ example.com
│     │  │  ├─ proxy-ssl-certificate.conf
│     │  │  ├─ ssl-certificate.conf
│     │  │  └─ ssl-client-certificate.conf
│     │  ├─ acme-challenge.conf
│     │  ├─ base-headers.conf
│     │  ├─ base-options.conf
│     │  ├─ brotli-options.conf
│     │  ├─ force-https.conf
│     │  ├─ force-non-www.conf
│     │  ├─ gzip-options.conf
│     │  ├─ map-connection.conf
│     │  ├─ map-non-www.conf
│     │  ├─ proxy-options.conf
│     │  ├─ proxy-ssl-options.conf
│     │  ├─ ssl-client-options.conf
│     │  ├─ ssl-dhparam.conf
│     │  ├─ ssl-headers.conf
│     │  └─ ssl-options.conf
│     ├─ ssl
│     │  ├─ example.com
│     │  │  ├─ cert.pem
│     │  │  ├─ chain.pem
│     │  │  ├─ fullchain.pem
│     │  │  └─ privkey.pem
│     │  └─ dhparam.pem
│     ├─ nginx.conf
│     └─ nginx.conf.template
├─ usr
│  ├─ bin
│  │  └─ envsubst
│  ├─ local
│  │  ├─ bin
│  │  │  ├─ acme
│  │  │  ├─ ae
│  │  │  ├─ cf
│  │  │  ├─ entrypoint
│  │  │  └─ ng
│  │  └─ lib
│  │     ├─ color.sh
│  │     └─ log.sh
│  └─ sbin
│     └─ nginx
├─ log
│  ├─ ae
│  │  └─ output.log
│  ├─ cf
│  │  └─ output.log
│  └─ nginx
│     ├─ access.log
│     └─ error.log
└─ var
   └─ www
      └─ example.com
```

</details>

## Acknowledgements

This image would not have happened without studying other people's project.

[wokalek/nginx-brotli] \
The creation of this image began with studying Alexander Wokalek's work. His image formed the basis of this image with almost no changes. In a sense, this project is a fork of that one. If you are looking for Nginx without additional overhead, but with only the brotli module compiled, consider using wokalek's image.

[nginx-le/nginx-le] \
The image created by [Umputun] demonstrated how to work with scripts that process SSL certificates within the same image with Nginx.

[h5bp/server-configs-nginx], [lebinh/nginx-conf] \
I would like to mention several resources in one line from which snippets were collected.

[Mozilla SSL Configuration Generator], [Report URI Content Security Policy Generator] \
Let us not forget about useful generators, which also helped to form a few snippets.

## License

[MIT] (c) [Ivan Uhalin]

<!-- Footnotes -->

[acmesh-official/acme.sh]: https://github.com/acmesh-official/acme.sh/
[google/ngx_brotli]: https://github.com/google/ngx_brotli/
[h5bp/server-configs-nginx]: https://github.com/h5bp/server-configs-nginx/
[lebinh/nginx-conf]: https://github.com/lebinh/nginx-conf/
[nginx-le/nginx-le]: https://github.com/nginx-le/nginx-le
[wokalek/nginx-brotli]: https://github.com/wokalek/nginx-brotli/

[GNU envsubst]: https://www.gnu.org/software/gettext/manual/html_node/envsubst-Invocation.html

[Mozilla SSL Configuration Generator]: https://ssl-config.mozilla.org/
[Report URI Content Security Policy Generator]: https://report-uri.com/home/generate/

[Ivan Uhalin]: https://github.com/vanyauhalin/
[Umputun]: https://github.com/umputun/

[MIT]: https://github.com/vanyauhalin/docker-nginx/blob/main/LICENSE/
