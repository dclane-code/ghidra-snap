# image-garden(1) project customization (https://gitlab.com/zygoon/image-
# garden): bakes the slow, one-off parts of spread.yaml's suite prepare: into
# each system's VM image, so they run once when image-garden first builds the
# image rather than on every spread run. Editing this file regenerates each
# image's cloud-init user-data and so rebuilds the image, as does the image
# getting older than GARDEN_IMAGE_MAX_AGE_DAYS (see below). This only saves
# time locally: CI (zyga/image-garden-action) only caches the pristine
# downloaded images, not prepared ones (its cache-prepared-images input is
# off by default, and documented as scaling poorly with the number of
# systems), so it builds a fresh image from this file on every run anyway.
#
# This is purely a cache: spread.yaml's prepare: still does the same setup
# idempotently (cheap no-ops once baked in), so a stale or partially
# provisioned image still ends up correct, and the per-test packages below
# are still declared by each tests/*/task.yaml that needs them.
#
# Each template appends to the default template's trailing runcmd: list (see
# "Cloud-init templates" in image-garden(1)). runcmd failures don't abort
# provisioning - they only show up in <system>.<arch>.qcow2.log - which is
# fine given the spread.yaml fallback above.

APT_TEST_PACKAGES = xvfb fonts-dejavu-core
DNF_TEST_PACKAGES = xorg-x11-server-Xvfb dejavu-sans-fonts

define APT_RUNCMD
- DEBIAN_FRONTEND=noninteractive apt-get update
- DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confold" -o Dpkg::Options::="--force-confdef" upgrade -y
- DEBIAN_FRONTEND=noninteractive apt-get autoremove --purge -y
- DEBIAN_FRONTEND=noninteractive apt-get install -y snapd git gcc $(APT_TEST_PACKAGES)
endef

# disabling SELinux here takes effect on the next boot, since image-garden's
# provisioning boot always ends by powering off - this replaces the
# disable-and-REBOOT dance spread.yaml would otherwise do on every run
define DNF_RUNCMD
- sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
- dnf upgrade -y
- dnf install -y epel-release
- dnf install -y selinux-policy selinux-policy-targeted snapd git gcc $(DNF_TEST_PACKAGES)
- systemctl enable snapd.socket
- ln -sf /var/lib/snapd/snap /snap
endef

GARDEN_IMAGE_MAX_AGE_DAYS ?= 7
GARDEN_STALE_IMAGES := $(shell find . -maxdepth 1 -name '*.qcow2' ! -name '*.efi-*.qcow2' -mmin +$$(( $(GARDEN_IMAGE_MAX_AGE_DAYS) * 24 * 60 )) -printf '%f\n')
$(GARDEN_STALE_IMAGES): image-garden-force-rebuild
.PHONY: image-garden-force-rebuild
image-garden-force-rebuild:

define UBUNTU_CLOUD_INIT_USER_DATA_TEMPLATE
$(CLOUD_INIT_USER_DATA_TEMPLATE)
$(APT_RUNCMD)
endef

define DEBIAN_CLOUD_INIT_USER_DATA_TEMPLATE
$(CLOUD_INIT_USER_DATA_TEMPLATE)
$(APT_RUNCMD)
endef

define CENTOS_CLOUD_INIT_USER_DATA_TEMPLATE
$(CLOUD_INIT_USER_DATA_TEMPLATE)
$(DNF_RUNCMD)
endef

define ROCKY_CLOUD_INIT_USER_DATA_TEMPLATE
$(CLOUD_INIT_USER_DATA_TEMPLATE)
$(DNF_RUNCMD)
endef
