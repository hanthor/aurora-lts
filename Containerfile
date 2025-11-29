ARG MAJOR_VERSION="${MAJOR_VERSION:-c10s}"
ARG AKMODS_VERSION="${AKMODS_VERSION:-centos-10}"

# Import akmods sources
FROM ghcr.io/ublue-os/akmods-zfs:${AKMODS_VERSION} AS akmods_zfs
FROM ghcr.io/ublue-os/akmods-nvidia-open:${AKMODS_VERSION} AS akmods_nvidia_open

# Merge system files 
FROM cgr.dev/chainguard/wolfi-base:latest@sha256:42012fa027adc864efbb7cf68d9fc575ea45fe1b9fb0d16602e00438ce3901b1 AS context
COPY --from=ghcr.io/projectbluefin/common:latest@sha256:e10f4af0f9d508d4661f4426c1c835ce02a770787e8d1561758ee953dfde06a7 /system_files /common-files
COPY --from=ghcr.io/get-aurora-dev/common:latest@sha256:ad0b6c8fd986bcf5e63162cd79397168170f197065b39278370f23dddc67a65a /system_files/shared /aurora-files
COPY --from=ghcr.io/get-aurora-dev/common:latest@sha256:ad0b6c8fd986bcf5e63162cd79397168170f197065b39278370f23dddc67a65a /brew /brew
COPY --from=ghcr.io/get-aurora-dev/common:latest@sha256:ad0b6c8fd986bcf5e63162cd79397168170f197065b39278370f23dddc67a65a /just /just
COPY --from=ghcr.io/get-aurora-dev/common:latest@sha256:ad0b6c8fd986bcf5e63162cd79397168170f197065b39278370f23dddc67a65a /flatpaks /flatpaks
COPY --from=ghcr.io/get-aurora-dev/common:latest@sha256:ad0b6c8fd986bcf5e63162cd79397168170f197065b39278370f23dddc67a65a /logos /logos
COPY --from=ghcr.io/hanthor/artwork/aurora-wallpapers:latest@sha256:da619db0ca0b4c151f58a83aeb50610b76199b94dd1d7b5832d0f2181c7e3359 / /wallpapers
COPY system_files /lts-files
COPY system_files_overrides /overrides
COPY build_scripts /build_scripts

# Merge
RUN apk add --no-cache rsync && \
    mkdir -p /files/usr/share/ublue-os/just /files/usr/share/ublue-os/homebrew /files/usr/share/backgrounds && \
    rsync -av /common-files/ /files/ && \
    rsync -av /aurora-files/ /files/ && \
    rsync -av /lts-files/ /files/ && \
    rsync -av /wallpapers/ /files/usr/share/backgrounds/aurora/ && \
    find /just -iname '*.just' -exec printf "\n\n" \; -exec cat {} \; >> /files/usr/share/ublue-os/just/60-custom.just && \
    cp /brew/*.Brewfile /files/usr/share/ublue-os/homebrew/ && \
    tree /files && \
    ls -lah /files/usr/lib/systemd/system/

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

