# Build environment

FROM debian:stretch

RUN apt-get update && \
    apt-get install --no-install-recommends -y \
        autoconf \
        automake \
        build-essential \
        ca-certificates \
        dpkg \
        fakeroot \
        git \
        gnome-shell \
        inkscape \
        libgdk-pixbuf2.0-dev \
        libglib2.0-dev \
        libsass0 \
        libxml2-utils \
        parallel \
        pkg-config \
        sassc
