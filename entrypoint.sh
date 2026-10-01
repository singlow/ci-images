#!/usr/bin/env bash
set -e

echo "Run CodeSigner"

CURRENT_ENV="Production"
JVM_OPTS=$(echo "$JVM_OPTS" | tr -d '"')
ENVIRONMENT_NAME=$(echo "$ENVIRONMENT_NAME" | tr -d '"')
if [[ $ENVIRONMENT_NAME != "PROD" ]]; then
    cp /codesign/conf/code_sign_tool.properties /codesign/conf/code_sign_tool.properties.production
    cp /codesign/conf/code_sign_tool_demo.properties /codesign/conf/code_sign_tool.properties
    CURRENT_ENV="Sandbox"
fi

echo "Running ESigner.com CodeSign Action on $CURRENT_ENV [$JVM_OPTS]"
echo ""

# Exec the specified command or fall back on bash
if [ $# -eq 0 ]; then
    CMD=( "bash" )
else
    CMD=( "$@" )
fi

# Arguments, not a shell string. Passwords and paths must reach java unchanged.
args=(java)
if [[ -n ${JVM_OPTS:-} ]]; then
    # Space-separated java flags, not one argument.
    read -r -a jvm_opts <<< "$JVM_OPTS"
    args+=("${jvm_opts[@]}")
fi
args+=(-jar "${CODE_SIGN_TOOL_PATH}/jar/code_sign_tool-1.3.1.jar")
args+=("${CMD[@]}")

# Authentication Info
if [[ ! "${CMD[*]}" =~ --help ]]; then
  [[ -n ${USERNAME:-} ]] && args+=("-username=${USERNAME}")
  [[ -n ${PASSWORD:-} ]] && args+=("-password=${PASSWORD}")

  if [[ ! "${CMD[*]}" =~ get_credential_ids ]]; then
      [[ -n ${CREDENTIAL_ID:-} ]] && args+=("-credential_id=${CREDENTIAL_ID}")
      if [[ ! "${CMD[*]}" =~ credential_info ]]; then
        [[ -n ${TOTP_SECRET:-} ]] && args+=("-totp_secret=${TOTP_SECRET}")
        [[ -n ${PROGRAM_NAME:-} ]] && args+=("-program_name=${PROGRAM_NAME}")
        [[ -n ${FILE_PATH:-} ]] && args+=("-input_file_path=${FILE_PATH}")
        [[ -n ${OUTPUT_PATH:-} ]] && args+=("-output_dir_path=${OUTPUT_PATH}")
      fi
  fi
fi

# CodeSignTool can print an error and still exit 0.
# Keep the tool's output when it exits non-zero. The check below decides success.
set +e
RESULT=$("${args[@]}" 2>&1)
status=$?
set -e
if [[ $status -ne 0 || "$RESULT" =~ .*"Error".* || "$RESULT" =~ .*"Exception".* || "$RESULT" =~ .*"Missing required option".* || $RESULT =~ .*"Unmatched arguments from".* || $RESULT =~ .*"Unmatched argument".* || $RESULT =~ .*"Not a valid output directory".* ]]; then
  echo "Something Went Wrong. Please try again."
  echo "$RESULT"
  exit 1
else
  if [[ "${CMD[*]}" =~ sign ]]; then
    LOG_USERNAME=$(echo "$USERNAME" | sed "s/\"//g")
    LOG_CREDENTIAL_ID=$(echo "$CREDENTIAL_ID" | sed "s/\"//g")
    echo "Code signed successfully by ${LOG_USERNAME} using ${LOG_CREDENTIAL_ID} credential id"
  fi
  echo "$RESULT"
fi

exit 0
