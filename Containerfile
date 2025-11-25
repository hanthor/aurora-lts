ARG MAJOR_VERSION="${MAJOR_VERSION:-c10s}"
ARG AKMODS_VERSION="${AKMODS_VERSION:-centos-10}"

# Import akmods sources
FROM ghcr.io/ublue-os/akmods-zfs:${AKMODS_VERSION} AS akmods_zfs
FROM ghcr.io/ublue-os/akmods-nvidia-open:${AKMODS_VERSION} AS akmods_nvidia_open

# Merge system files 
FROM alpine:latest AS context
COPY --from=ghcr.io/projectbluefin/common:latest /system_files /common-files
COPY --from=ghcr.io/hanthor/aurora-oci:latest /system_files /aurora-files
COPY --from=ghcr.io/hanthor/aurora-oci:latest /brew /brew
COPY --from=ghcr.io/hanthor/aurora-oci:latest /just /just
COPY --from=ghcr.io/hanthor/aurora-oci:latest /flatpaks /flatpaks
COPY --from=ghcr.io/hanthor/aurora-oci:latest /logos /logos
COPY system_files /lts-files
COPY system_files_overrides /overrides
COPY build_scripts /build_scripts

# Merge
RUN mkdir -p /files/usr/share/ublue-os/just /files/usr/share/ublue-os/homebrew && \
    cp -av /common-files/. /files/ && \
    cp -av /aurora-files/. /files/ && \
    cp -av /lts-files/. /files/ && \
    find /just -iname '*.just' -exec printf "\n\n" \; -exec cat {} \; >> /files/usr/share/ublue-os/just/60-custom.just && \
    cp /brew/*.Brewfile /files/usr/share/ublue-os/homebrew/

# Final image
FROM quay.io/centos-bootc/centos-bootc:$MAJOR_VERSION

ARG ENABLE_GDX="${ENABLE_GDX:-0}"
ARG ENABLE_HWE="${ENABLE_HWE:-0}"
ARG IMAGE_NAME="${IMAGE_NAME:-aurora}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR:-ublue-os}"
ARG SHA_HEAD_SHORT="${SHA_HEAD_SHORT:-deadbeef}"

RUN --mount=type=tmpfs,dst=/opt \
    --mount=type=tmpfs,dst=/tmp \
    --mount=type=tmpfs,dst=/var \
    --mount=type=tmpfs,dst=/boot \
    --mount=type=bind,from=akmods_zfs,src=/rpms,dst=/tmp/akmods-zfs-rpms \
    --mount=type=bind,from=akmods_zfs,src=/kernel-rpms,dst=/tmp/kernel-rpms \
    --mount=type=bind,from=akmods_nvidia_open,src=/rpms,dst=/tmp/akmods-nvidia-open-rpms \
    --mount=type=bind,from=context,source=/,target=/run/context \
    /run/context/build_scripts/build.sh

# Make /opt writeable by default
RUN rm -rf /opt && ln -s /var/opt /opt