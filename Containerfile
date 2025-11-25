ARG MAJOR_VERSION="${MAJOR_VERSION:-c10s}"
ARG BASE_IMAGE_SHA="${BASE_IMAGE_SHA:-sha256-feea845d2e245b5e125181764cfbc26b6dacfb3124f9c8d6a2aaa4a3f91082ed}"
ARG ENABLE_HWE="${ENABLE_HWE:-0}"
ARG AKMODS_VERSION="${AKMODS_VERSION:-centos-10}"
# Upstream mounts akmods-zfs and akmods-nvidia-open; select their tag via AKMODS_VERSION
FROM ghcr.io/ublue-os/akmods-zfs:${AKMODS_VERSION} AS akmods_zfs
FROM ghcr.io/ublue-os/akmods-nvidia-open:${AKMODS_VERSION} AS akmods_nvidia_open
FROM scratch AS context

# Copy local system files first (LTS-specific overrides)
COPY system_files /files

# Copy shared configuration from common OCI image
COPY --from=ghcr.io/projectbluefin/common:latest /system_files /files

# Copy Aurora-specific configuration from aurora-oci image
# System files go to /files (will be copied to / by build scripts)
COPY --from=ghcr.io/hanthor/aurora-oci:latest /system_files /files

# Brew files need to be accessible at /brew for build scripts
COPY --from=ghcr.io/hanthor/aurora-oci:latest /brew /brew

# Flatpak lists need to be accessible at /flatpaks for build scripts
COPY --from=ghcr.io/hanthor/aurora-oci:latest /flatpaks /flatpaks

# Just files need to be accessible at /just for build scripts
COPY --from=ghcr.io/hanthor/aurora-oci:latest /just /just

# Logos need to be accessible at /logos for branding scripts
COPY --from=ghcr.io/hanthor/aurora-oci:latest /logos /logos

# Copy LTS-specific overrides last (highest priority)
COPY system_files_overrides /overrides
COPY build_scripts /build_scripts

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
