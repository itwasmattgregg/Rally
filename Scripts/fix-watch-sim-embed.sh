#!/bin/bash
# When building the iOS app for the simulator, Xcode sometimes embeds a
# device (watchos) Watch binary, which fails ValidateEmbeddedBinary and
# leaves WatchConnectivity unable to see a counterpart.
#
# Prefer the watchsimulator product if it exists; otherwise strip the
# mismatched Watch folder so the iOS sim build still succeeds (install the
# Watch app via the "Rally Watch App" scheme afterward).

set -euo pipefail

if [[ "${PLATFORM_NAME:-}" != "iphonesimulator" ]]; then
  exit 0
fi

APP_WATCH_DIR="${TARGET_BUILD_DIR}/${WRAPPER_NAME}/Watch"
WATCH_NAME="Rally Watch App.app"
SIM_WATCH="${BUILD_DIR}/Debug-watchsimulator/${WATCH_NAME}"

if [[ -d "${SIM_WATCH}" ]]; then
  mkdir -p "${APP_WATCH_DIR}"
  rm -rf "${APP_WATCH_DIR}/${WATCH_NAME}"
  cp -R "${SIM_WATCH}" "${APP_WATCH_DIR}/${WATCH_NAME}"
  echo "note: Embedded watchsimulator companion at ${APP_WATCH_DIR}/${WATCH_NAME}"
  exit 0
fi

if [[ -d "${APP_WATCH_DIR}/${WATCH_NAME}" ]]; then
  # Drop a device-watchOS embed that would fail simulator validation.
  DT_PLATFORM=$(/usr/libexec/PlistBuddy -c 'Print :DTPlatformName' "${APP_WATCH_DIR}/${WATCH_NAME}/Info.plist" 2>/dev/null || true)
  if [[ "${DT_PLATFORM}" == "watchos" ]]; then
    echo "warning: Removing device-watchOS embed from iphonesimulator app (build Watch scheme for simulator first for WC)."
    rm -rf "${APP_WATCH_DIR}"
  fi
fi
