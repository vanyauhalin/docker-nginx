# Changelog

This document records all notable changes to the project, following the [Keep a Changelog] format and adhering to [Semantic Versioning].

## [Unreleased]

<!-- There are no noticeable changes in version [unreleased]. -->

### Changed

- **Breaking** Change the redirect status from 301 to 308 for the `force-https` snippet ([f530788]).
- **Breaking** Change the redirect status from 301 to 308 for the `force-non-www` snippet ([723658b]).
- Use the certificate itself instead of its full chain to check the expiration ([3f29803]).
- Use a more concise and generic User-Agent ([7e8eed5], [f6964d4]).
- Improve the `ae` log messages a bit ([d05eb82]).
- Check the existence of all SLL files for the `ae` guard option ([917f105]).

## [0.0.2] - 2024-01-15

### Changed

- **Breaking** Separate headers for the proxy with its options ([1a4da68]).
- Use the ISO 8601 date format in log messages ([92e3f61], [8984d77]).
- Use colors in log messages ([92e3f61]).

### Fixed

- Add a snippet to set the `connection_upgrade` variable ([fa70f5d]).

## [0.0.1] - 2024-10-19

This is the first, initial release. The version 0.0.1 was chosen to test the publishing process and attempt to integrate it into other projects. If everything functions well, the version will be updated to 0.1.0, possibly with some changes.

### Added

- A static Brotli module.
- The `ae` script for obtaining SSL certificates with their auto-renewal.
- The `ng` script for substituting environment variables in the Nginx configuration.
- A few basic snippets to configure Nginx.

<!-- Footnotes -->

[Keep a Changelog]: https://keepachangelog.com/en/1.1.0/
[Semantic Versioning]: https://semver.org/spec/v2.0.0.html

[Unreleased]: https://github.com/vanyauhalin/docker-nginx/compare/v0.0.2...HEAD/
[0.0.2]: https://github.com/vanyauhalin/docker-nginx/releases/tag/v0.0.2/
[0.0.1]: https://github.com/vanyauhalin/docker-nginx/releases/tag/v0.0.1/

[f6964d4]: https://github.com/vanyauhalin/docker-nginx/commit/f6964d4d73d2069d26f8b9018c850aec33681e71/
[917f105]: https://github.com/vanyauhalin/docker-nginx/commit/917f105b31a48c05c7249f64a2d3925f9f0aeb55/
[d05eb82]: https://github.com/vanyauhalin/docker-nginx/commit/d05eb82634c5061cac6e11eb869489b142f5fc4e/
[7e8eed5]: https://github.com/vanyauhalin/docker-nginx/commit/7e8eed5f557a222380174fd08ea49fc46325e5da/
[3f29803]: https://github.com/vanyauhalin/docker-nginx/commit/3f298034d9375866ecc516c67ced9da4c55b96c7/
[f530788]: https://github.com/vanyauhalin/docker-nginx/commit/f530788af035215a7ffc4b3aab900ea56a94cdf5/
[723658b]: https://github.com/vanyauhalin/docker-nginx/commit/723658b073699e3e6e91475a4599ce1de21c46c0/
[8984d77]: https://github.com/vanyauhalin/docker-nginx/commit/8984d778385708ce47d793ee081ba73fdd13977c/
[fa70f5d]: https://github.com/vanyauhalin/docker-nginx/commit/fa70f5d36426bb9d1097ed8007ba96bb3eddfb22/
[92e3f61]: https://github.com/vanyauhalin/docker-nginx/commit/92e3f611618f591ac8457bf9fbd15d05e51d0477/
[1a4da68]: https://github.com/vanyauhalin/docker-nginx/commit/1a4da68f722bcccf2adde746ba46fc7699b7a53a/
