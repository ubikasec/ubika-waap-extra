#!/usr/bin/env sh
#
# Script to deploy certificates to your UBIKA WAAP Gateway cluster.
#
# The following variables can be exported:
#
# DEPLOY_UBIKA_WAAP_GW_API_URL (mandatory)
#   The URL to access the UBIKA WAAP Gateaway API
#
# DEPLOY_UBIKA_WAAP_GW_API_KEY (mandatory)
#   The API KEY to authenticate to the API
#
# DEPLOY_UBIKA_WAAP_GW_INSECURE (optional)
#   Connect to the UBIKA WAAP Gateaway without verifying the HTTPS certificate (yes/no)
#   Note that this parameter set to "no" does not have precedence on the --insecure flag of acme.sh
#   This parameter defaults to "yes"
#
# DEPLOY_UBIKA_WAAP_GW_APPLY (optional)
#   Apply the tunnels related to this certificate and issue a warm restart (yes/no)
#   This parameter defaults to "yes"
#
# export DEPLOY_UBIKA_WAAP_GW_API_URL="https://my_management_ip:3001/api/v1/"
# export DEPLOY_UBIKA_WAAP_GW_API_KEY="my_api_key"
# export DEPLOY_UBIKA_WAAP_GW_INSECURE="yes"
# export DEPLOY_UBIKA_WAAP_GW_APPLY="yes"

########  Public functions #####################

#domain keyfile certfile cafile fullchain
ubika_waap_gw_deploy() {
    _cdomain="$1"
    _ckey="$2"
    _ccert="$3"
    _cca="$4"
    _cfullchain="$5"

    _debug _cdomain "${_cdomain}"
    _debug _ckey "${_ckey}"
    _debug _ccert "${_ccert}"
    _debug _cca "${_cca}"
    _debug _cfullchain "${_cfullchain}"

    _getdeployconf DEPLOY_UBIKA_WAAP_GW_API_URL
    _getdeployconf DEPLOY_UBIKA_WAAP_GW_API_KEY
    if [ -n "${DEPLOY_UBIKA_WAAP_GW_API_URL}" ] && [ -n "${DEPLOY_UBIKA_WAAP_GW_API_KEY}" ]; then
        _savedeployconf DEPLOY_UBIKA_WAAP_GW_API_URL "${DEPLOY_UBIKA_WAAP_GW_API_URL}"
        _savedeployconf DEPLOY_UBIKA_WAAP_GW_API_KEY "${DEPLOY_UBIKA_WAAP_GW_API_KEY}"
        _info "[UBIKA deploy-hook] Deploy certificate remotely through API."
    else
        [ -z "${DEPLOY_UBIKA_WAAP_GW_API_URL}" ] && _err '[UBIKA deploy-hook] You must provide the DEPLOY_UBIKA_WAAP_GW_API_URL variable'
        [ -z "${DEPLOY_UBIKA_WAAP_GW_API_KEY}" ] && _err '[UBIKA deploy-hook] You must provide the DEPLOY_UBIKA_WAAP_GW_API_KEY variable'
        return 1
    fi
    _getdeployconf DEPLOY_UBIKA_WAAP_GW_INSECURE
    [ -n "${DEPLOY_UBIKA_WAAP_GW_INSECURE}" ] || DEPLOY_UBIKA_WAAP_GW_INSECURE="yes"
    _getdeployconf DEPLOY_UBIKA_WAAP_GW_APPLY
    [ -n "${DEPLOY_UBIKA_WAAP_GW_APPLY}" ] || DEPLOY_UBIKA_WAAP_GW_APPLY="yes"
    _savedeployconf DEPLOY_UBIKA_WAAP_GW_APPLY "${DEPLOY_UBIKA_WAAP_GW_APPLY}"

    _debug DEPLOY_UBIKA_WAAP_GW_API_URL "${DEPLOY_UBIKA_WAAP_GW_API_URL}"
    _secure_debug DEPLOY_UBIKA_WAAP_GW_API_KEY "${DEPLOY_UBIKA_WAAP_GW_API_KEY}"
    _debug DEPLOY_UBIKA_WAAP_GW_INSECURE "${DEPLOY_UBIKA_WAAP_GW_INSECURE}"
    _debug DEPLOY_UBIKA_WAAP_GW_APPLY "${DEPLOY_UBIKA_WAAP_GW_APPLY}"

    [ "${DEPLOY_UBIKA_WAAP_GW_INSECURE}" = "yes" ] && HTTPS_INSECURE="1"
    _debug API_HTTPS_Insecure "${HTTPS_INSECURE}"

    _api_cert_endpoint="${DEPLOY_UBIKA_WAAP_GW_API_URL}/certificates"
    _debug API_Cert_Endpoint "${_api_cert_endpoint}"
    _api_apply_endpoint="${DEPLOY_UBIKA_WAAP_GW_API_URL}/apply"
    _debug API_Apply_Endpoint "${_api_apply_endpoint}"

    _H1="Authorization: Bearer ${DEPLOY_UBIKA_WAAP_GW_API_KEY}"
    _secure_debug2 _H1 "${_H1}"

    # STEP 1 - Get the certificate UID
    if _response=$(_get "${_api_cert_endpoint}"); then
        _cert_uid=$(echo "$_response" | jq -r --arg name "${_cdomain}" '.data[] | select(.commonName == $name) | .uid')
        _debug Certificate_UID "${_cert_uid}"
    else
        _err '[UBIKA deploy-hook] Error while contacting the WAAP Gateway API, check the parameters'
        return 1
    fi

    # STEP 2 - Upload the certificate
    _upload_body="
    {
        \"name\":            \"${_cdomain}\",
        \"privateKeyName\":  \"$(basename "${_ckey}")\",
        \"certificateName\": \"$(basename "${_ccert}")\",
        \"privateKey\":      \"$(base64 "${_ckey}" | tr -d '\n')\",
        \"certificate\":     \"$(base64 "${_ccert}" | tr -d '\n')\",
        \"chain\":           \"$(base64 "${_cca}" | tr -d '\n')\"
    }"
    _secure_debug2 Certificate_Payload "${_upload_body}"
    if [ -z "${_cert_uid}" ]; then
        _info "[UBIKA deploy-hook] A certificate for ${_cdomain} is not present in the product, creating the certificate..."
        _response=$(_post "${_upload_body}" "${_api_cert_endpoint}" 0 POST 'application/json' | base64 -d)
    else
        _info "[UBIKA deploy-hook] A certificate for ${_cdomain} is already present in the product (uid ${_cert_uid}), updating the certificate..."
        _response=$(_post "${_upload_body}" "${_api_cert_endpoint}?uid=${_cert_uid}" 0 PUT 'application/json' | base64 -d)
    fi
    _ret=$?
    _debug2 API_Upload_Response "${_response}"
    if [ "${_ret}" -ne 0 ]; then
        _err '[UBIKA deploy-hook] Error while contacting the WAAP Gateway API, check the parameters'
        return 1
    else
        ubika_waap_gw_check_api_call "${_response}" || return 1
    fi
    if [ -z "${_cert_uid}" ]; then
        _cert_uid=$(echo "$_response" | jq -r '.data.uid')
        _debug2 Certificate_UID "${_cert_uid}"
    fi

    # Step 3 - Apply the tunnels
    if [ "${DEPLOY_UBIKA_WAAP_GW_APPLY}" = "yes" ]; then
        _apply_body="
        {
            \"SSLKeyUid\": { \"uid\": \"${_cert_uid}\" },
            \"coldRestart\": false
        }"
        _info "[UBIKA deploy-hook] Issuing a warm restart of tunnels using the certificate..."
        _response=$(_post "${_apply_body}" "${_api_apply_endpoint}" 0 POST 'application/json' | base64 -d)
        _debug2 API_Apply_Response "${_response}"
        ubika_waap_gw_check_api_call "${_response}" || return 1
    fi

    return 0
}

####################  Private functions below ##################################
ubika_waap_gw_check_api_call() {
    _response=$1
    if [ "$(echo "${_response}" | jq -r 'has("error")')" == "true" ]; then
        _error_code=$(echo "${_response}" | jq -r '.error.code')
        _error_message=$(echo "${_response}" | jq -r '.error.message')
        _err "[UBIKA deploy-hook] Error ${_error_code}: ${_error_message}"
        return 1
    else
        _info "[UBIKA deploy-hook] Success"
    fi
    return 0
}
