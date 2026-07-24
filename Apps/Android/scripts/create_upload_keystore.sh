#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPOSITORY_DIR="$(cd "${PROJECT_DIR}/../.." && pwd)"
export JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home}"

KEYTOOL="${JAVA_HOME}/bin/keytool"
KEYSTORE_DIR="${REPOSITORY_DIR}/private/android"
KEYSTORE_PATH="${KEYSTORE_DIR}/dday-upload-key.jks"
CERTIFICATE_PATH="${KEYSTORE_DIR}/dday-upload-certificate.pem"
PROPERTIES_PATH="${PROJECT_DIR}/keystore.properties"
KEY_ALIAS="dday-upload"

if [[ ! -x "${KEYTOOL}" ]]; then
    echo "keytool was not found at ${KEYTOOL}." >&2
    exit 1
fi

if [[ -e "${KEYSTORE_PATH}" || -e "${PROPERTIES_PATH}" ]]; then
    echo "An Android upload keystore is already configured." >&2
    echo "Refusing to overwrite ${KEYSTORE_PATH} or ${PROPERTIES_PATH}." >&2
    exit 1
fi

if [[ ! -t 0 ]]; then
    echo "Run this script from an interactive terminal." >&2
    exit 1
fi

read -r -s -p "Create an upload-key password (12+ characters): " upload_password
echo
read -r -s -p "Confirm the password: " upload_password_confirmation
echo

if [[ "${upload_password}" != "${upload_password_confirmation}" ]]; then
    echo "Passwords do not match." >&2
    exit 1
fi

if (( ${#upload_password} < 12 )); then
    echo "Use a password with at least 12 characters." >&2
    exit 1
fi

umask 077
mkdir -p "${KEYSTORE_DIR}"

export DDAY_UPLOAD_PASSWORD="${upload_password}"
trap 'unset DDAY_UPLOAD_PASSWORD upload_password upload_password_confirmation' EXIT

"${KEYTOOL}" \
    -genkeypair \
    -v \
    -storetype PKCS12 \
    -keystore "${KEYSTORE_PATH}" \
    -storepass:env DDAY_UPLOAD_PASSWORD \
    -alias "${KEY_ALIAS}" \
    -keypass:env DDAY_UPLOAD_PASSWORD \
    -keyalg RSA \
    -keysize 4096 \
    -validity 10000 \
    -dname "CN=Dday Android Upload, OU=Development, O=Dday, C=KR"

"${KEYTOOL}" \
    -exportcert \
    -rfc \
    -keystore "${KEYSTORE_PATH}" \
    -storepass:env DDAY_UPLOAD_PASSWORD \
    -alias "${KEY_ALIAS}" \
    -file "${CERTIFICATE_PATH}"

{
    printf 'storeFile=../../private/android/dday-upload-key.jks\n'
    printf 'keyAlias=%s\n' "${KEY_ALIAS}"
} > "${PROPERTIES_PATH}"

chmod 600 "${KEYSTORE_PATH}" "${PROPERTIES_PATH}"

echo
echo "Upload keystore created at ${KEYSTORE_PATH}"
echo "Public certificate created at ${CERTIFICATE_PATH}"
echo "Back up the keystore and password separately before the first Play upload."
