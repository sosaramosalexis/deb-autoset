#!/usr/bin/env bash
set -euo pipefail

SUDO_USER_NAME="${1:-asosar}"
SUDOERS_FILE="/etc/sudoers.d/${SUDO_USER_NAME}"
PACKAGES=(sudo net-tools curl cockpit)

if [[ "${EUID}" -ne 0 ]]; then
  echo "Please run this script as root:"
  echo "  su -"
  echo "  bash $0 ${SUDO_USER_NAME}"
  exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
  echo "This script is intended for Debian-based systems with apt-get."
  exit 1
fi

if ! id "${SUDO_USER_NAME}" >/dev/null 2>&1; then
  echo "User '${SUDO_USER_NAME}' does not exist. Create the user first or pass a different username:"
  echo "  bash $0 your_username"
  exit 1
fi

echo "Updating package lists..."
apt-get update

echo "Installing packages: ${PACKAGES[*]}"
DEBIAN_FRONTEND=noninteractive apt-get install -y "${PACKAGES[@]}"

echo "Granting sudo access to '${SUDO_USER_NAME}'..."
printf '%s ALL=(ALL:ALL) ALL\n' "${SUDO_USER_NAME}" > "${SUDOERS_FILE}"
chmod 0440 "${SUDOERS_FILE}"

if ! visudo -cf "${SUDOERS_FILE}"; then
  echo "Invalid sudoers file generated. Removing ${SUDOERS_FILE}."
  rm -f "${SUDOERS_FILE}"
  exit 1
fi

if command -v systemctl >/dev/null 2>&1; then
  echo "Enabling Cockpit socket..."
  systemctl enable --now cockpit.socket
else
  echo "systemctl not found; Cockpit was installed but not enabled automatically."
fi

echo "Done."
echo "Installed: ${PACKAGES[*]}"
echo "Sudo access configured for: ${SUDO_USER_NAME}"
