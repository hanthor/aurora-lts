ARG MAJOR_VERSION="${MAJOR_VERSION:-c10s}"
ARG BASE_IMAGE_SHA="${BASE_IMAGE_SHA:-sha256-feea845d2e245b5e125181764cfbc26b6dacfb3124f9c8d6a2aaa4a3f91082ed}"
ARG ENABLE_HWE="${ENABLE_HWE:-0}"
ARG AKMODS_VERSION="${AKMODS_VERSION:-centos-10}"
# Upstream mounts akmods-zfs and akmods-nvidia-open; select their tag via AKMODS_VERSION
FROM ghcr.io/ublue-os/akmods-zfs:${AKMODS_VERSION} AS akmods_zfs
FROM ghcr.io/ublue-os/akmods-nvidia-open:${AKMODS_VERSION} AS akmods_nvidia_open
FROM scratch AS context
# MERGE STAGE: Merge files from multiple sources in the correct priority order
FROM alpine:latest AS merger

# Copy each source to separate directories
COPY --from=ghcr.io/projectbluefin/common:latest /system_files /common-files
COPY --from=ghcr.io/hanthor/aurora-oci:latest /system_files /aurora-files
COPY --from=ghcr.io/hanthor/aurora-oci:latest /brew /brew
COPY --from=ghcr.io/hanthor/aurora-oci:latest /just /just


COPY system_files /lts-files
COPY system_files_overrides /overrides
COPY build_scripts /build_scripts

# Merge in priority order: common -> aurora -> lts (lts has highest priority)
RUN echo "=== MERGING FILES ===" && \
    mkdir -p /merged-files && \
    cp -av /common-files/. /merged-files/ && \
    cp -av /aurora-files/. /merged-files/ && \
    cp -av /lts-files/. /merged-files/ && \
    mkdir -p /merged-files/usr/share/ublue-os/just && \
    find /just -iname '*.just' -exec printf "\n\n" \; -exec cat {} \; >>/merged-files/usr/share/ublue-os/just/60-custom.just && \
    mkdir -p /merged-files/usr/share/ublue-os/homebrew && \
    cp /brew/*.Brewfile /merged-files/usr/share/ublue-os/homebrew/ && \

FROM scratch AS context

COPY --from=merger /merged-files /files
COPY --from=overrides /overrides /overrides
COPY --from=build_scripts /build_scripts /build_scripts
COPY --from=ghcr.io/hanthor/aurora-oci:latest /flatpaks /flatpaks
COPY --from=ghcr.io/hanthor/aurora-oci:latest /logos /logos



ARG MAJOR_VERSION="${MAJOR_VERSION:-c10s}"
FROM quay.io/centos-bootc/centos-bootc:$MAJOR_VERSION

ARG ENABLE_GDX="${ENABLE_GDX:-0}"
ARG ENABLE_HWE="${ENABLE_HWE:-0}"
ARG IMAGE_NAME="${IMAGE_NAME:-aurora}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR:-ublue-os}"
ARG MAJOR_VERSION="${MAJOR_VERSION:-lts}"
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

# Makes `/opt` writeable by default
# Needs to be here to make the main image build strict (no /opt there)
RUN rm -rf /opt && ln -s /var/opt /opt 
