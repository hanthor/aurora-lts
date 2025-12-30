ARG MAJOR_VERSION="${MAJOR_VERSION:-c10s}"
ARG AKMODS_VERSION="${AKMODS_VERSION:-centos-10}"
ARG COMMON_IMAGE_REF
ARG BREW_IMAGE_REF

# Import akmods sources
FROM ghcr.io/ublue-os/akmods-zfs:${AKMODS_VERSION} AS akmods_zfs
FROM ghcr.io/ublue-os/akmods-nvidia-open:${AKMODS_VERSION} AS akmods_nvidia_open
FROM ${COMMON_IMAGE_REF} AS common
FROM ${BREW_IMAGE_REF} AS brew

FROM scratch AS context
COPY system_files /files
COPY --from=common /system_files /files
COPY --from=common /wallpapers /files/shared
COPY --from=brew /system_files /files/shared
COPY system_files_overrides /overrides
COPY build_scripts /build_scripts

# https://github.com/get-aurora-dev/common
COPY --from=common /flatpaks /flatpaks
COPY --from=common /logos /logos

# Final image
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
RUN rm -rf /opt && ln -s /var/opt /opt 

