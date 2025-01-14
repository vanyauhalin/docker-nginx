# Changelog

This document records all notable changes to the project, following the [Keep a Changelog] format and adhering to [Semantic Versioning].

## [Unreleased]

There are no noticeable changes in version [unreleased].

### Changed

- **Breaking** Separate headers for the proxy with its options.

## [0.0.1] - 2024-10-19

This is the first, initial release. It is probably stable, but I want to test it with my projects for a few months first. This is why it is under the patch version, not a minor one. When I am sure that it works well, I will increase the version to 0.1.0 and mark it as stable.

### Added

- A static Brotli module.
- The `ae` script for obtaining SSL certificates with their auto-renewal.
- The `ng` script for substituting environment variables in the Nginx configuration.
- A few basic snippets to configure Nginx.

<!-- Footnotes -->

[Unreleased]: https://github.com/vanyauhalin/docker-nginx/compare/v0.0.1...HEAD/
[0.0.1]: https://github.com/vanyauhalin/docker-nginx/releases/tag/v0.0.1/

[Keep a Changelog]: https://keepachangelog.com/en/1.1.0/
[Semantic Versioning]: https://semver.org/spec/v2.0.0.html
