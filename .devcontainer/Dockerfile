# A named stage, because Dependabot updates FROM lines but not COPY --from=<image>
FROM ghcr.io/astral-sh/uv:0.12.21 AS uv

FROM mcr.microsoft.com/devcontainers/base:3.0.8-ubuntu24.04

COPY --from=uv /uv /uvx /usr/local/bin/
