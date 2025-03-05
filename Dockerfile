# Copyright (c) 2024 Erich L Foster
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
# of the Software, and to permit persons to whom the Software is furnished to do
# so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

ARG NEOVIM_VERSION="stable"
FROM ubuntu:22.04 as builder

ARG NEOVIM_VERSION

# Install dependencies needed for building devcontainers/cli and developing in neovim
RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  apt-utils \
  build-essential \
  curl \
  wget \
  nodejs \
  npm \
  lua5.1 \
  luajit \
  luarocks \
  git \
  # apt clean-up
  && apt-get autoremove -y \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

# Install NEOVIM
RUN \
  if [ "$NEOVIM_VERSION" = "stable" ]; then \
  curl -fLO https://github.com/neovim/neovim/releases/download/${NEOVIM_VERSION}/nvim-linux-x86_64.tar.gz; \
  else \
  curl -fLO https://github.com/neovim/neovim/releases/download/${NEOVIM_VERSION}/nvim-linux64.tar.gz; \
  fi \
  && rm -rf /opt/nvim \
  && tar -C /opt -xzf nvim-*.tar.gz \
  && ln -s /opt/nvim-*/bin/nvim /usr/local/bin/nvim \
  && chmod u+x /usr/local/bin/nvim

WORKDIR /app

# Installing the devcontainers CLI and Lua Dependencies for testing LUA projects
RUN npm install -g @devcontainers/cli@0.49.0 \
  && luarocks install busted

ENV USER_NAME=my-app
ARG GROUP_NAME=$USER_NAME
ARG USER_ID=1000
ARG GROUP_ID=$USER_ID

# Create user called my-app in ubuntu
RUN groupadd --gid $GROUP_ID $GROUP_NAME && \
  useradd --uid $USER_ID --gid $GROUP_ID -m $USER_NAME \
  && apt-get update \
  && apt-get install -y --no-install-recommends sudo \
  && echo $USER_NAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USER_NAME \
  && chmod 0440 /etc/sudoers.d/$USER_NAME

# Switch to user
USER $USER_NAME

# this will prevent the .local directory from being owned by root on bind mount
RUN mkdir -p /home/$USER_NAME/.local/share/nvim/lazy
