# Changelog

This document records all notable changes to the project, following the [Keep a Changelog] format and adhering to [Semantic Versioning].

## [Unreleased]

There are no noticeable changes in version [unreleased].

### Changed

- **Breaking** Separate headers for the proxy with its options ([1a4da68]).
- Use the ISO 8601 date format in log messages ([92e3f61], [8984d77]).
- Use colors in log messages ([92e3f61]).

### Fixed

- Add a snippet to set the `connection_upgrade` variable ([fa70f5d]).

## [0.0.1] - 2024-10-19

This is the first, initial release. It is probably stable, but I want to test it with my projects for a few months first. This is why it is under the patch version, not a minor one. When I am sure that it works well, I will increase the version to 0.1.0 and mark it as stable.

### Added

- A static Brotli module.
- The `ae` script for obtaining SSL certificates with their auto-renewal.
- The `ng` script for substituting environment variables in the Nginx configuration.
- A few basic snippets to configure Nginx.

<!-- Footnotes -->

[Keep a Changelog]: https://keepachangelog.com/en/1.1.0/
[Semantic Versioning]: https://semver.org/spec/v2.0.0.html

[Unreleased]: https://github.com/vanyauhalin/docker-nginx/compare/v0.0.1...HEAD/
[0.0.1]: https://github.com/vanyauhalin/docker-nginx/releases/tag/v0.0.1/

[8984d77]: https://github.com/vanyauhalin/docker-nginx/commit/8984d778385708ce47d793ee081ba73fdd13977c/
[fa70f5d]: https://github.com/vanyauhalin/docker-nginx/commit/fa70f5d36426bb9d1097ed8007ba96bb3eddfb22/
[92e3f61]: https://github.com/vanyauhalin/docker-nginx/commit/92e3f611618f591ac8457bf9fbd15d05e51d0477/
[1a4da68]: https://github.com/vanyauhalin/docker-nginx/commit/1a4da68f722bcccf2adde746ba46fc7699b7a53a/
