# [Choice] Debian / Ubuntu version: debian-10, debian-9, ubuntu-20.04, ubuntu-18.04
# See https://github.com/microsoft/vscode-dev-containers/tree/master/containers/debian
ARG VARIANT=debian-10
FROM mcr.microsoft.com/vscode/devcontainers/base:${VARIANT}


# This Dockerfile adds a non-root user with sudo access. Use the "remoteUser"
# property in devcontainer.json to use it. On Linux, the container user's GID/UIDs
# will be updated to match your local UID/GID (when using the dockerFile property).
# See https://aka.ms/vscode-remote/containers/non-root-user for details.
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Create the user
RUN \
    # groupadd --gid $USER_GID $USERNAME \
    # && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Set default user
USER $USERNAME



# RUN sudo apt update \
#     && sudo apt install snapd
# RUN sudo snap install hugo --channel=extended

RUN sudo wget https://github.com/gohugoio/hugo/releases/download/v0.147.2/hugo_extended_0.147.2_Linux-64bit.deb
RUN sudo dpkg -i hugo_extended_0.147.2_Linux-64bit.deb

# ** [Optional] Uncomment this section to install additional packages. **
#
# ENV DEBIAN_FRONTEND=noninteractive
# RUN apt-get update \
#    && apt-get -y install --no-install-recommends <your-package-list-here> \
#    #
#    # Clean up
#    && apt-get autoremove -y \
#    && apt-get clean -y \
#    && rm -rf /var/lib/apt/lists/*
# ENV DEBIAN_FRONTEND=dialog


# gh
COPY scripts/gh.sh /tmp/
RUN /tmp/gh.sh

# symlink gh config folder
RUN echo 'ln -s /config/gh /home/vscode/.config/gh ' >> ~/.bashrc


RUN sudo apt install -y make
