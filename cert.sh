#!/bin/bash

POSITIONAL_ARGS=()
LIFETIME=45 # set default lifetime of 45 days
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--certfile)
        CERTFILE="$2"
        shift # past argument=value
        shift # past vaule
        ;;
    -k|--keyfile)
        KEYFILE="$2"
        shift # past argument
        shift # past vaule
        ;;
    -l|--lifetime)
        LIFETIME="${2}"
        shift
        shift
        ;;
    -d|--debug)
        DEBUG="YES"
        shift # past argument
        ;;
    -p|--pem)
        PEM="$2"
        shift
        shift
        ;;
    -*|--*)
        echo "Unknown option $1"
        exit 1
        ;;
    *)
        POSITIONAL_ARGS+=($1)
        shift # past argument
        ;;

    esac
done

set -- "${POSITIONAL_ARGS[@]}"

#debug
LIFELEFT=$((LIFETIME * 86400))
if [ -x $(command -v tailscale) ] && [ -x $(command -v jq ) ];
then
    CERTCN=$(tailscale status --self --peers=false --json | jq -r .CertDomains[]);
else
    echo "Tailscale or jq not found or not in path";
    exit 1
fi
if [ -z "$CERTFILE" ]; then
        CERTFILE="${CERTCN}.crt"
fi
if [ -z "$KEYFILE" ]; then
        KEYFILE="${CERTCN}.key"
fi
if [[ $DEBUG ]];
then
echo "Certfile  = ${CERTFILE}"
echo "KEYFILE   = ${KEYFILE}"
echo "LIFETIME  = ${LIFETIME}"
echo "LIFELEFT  = ${LIFELEFT}"
echo "PEM       = ${PEM}"
fi
# script
if openssl x509 -in "${CERTFILE}" -checkend ${LIFELEFT} &>/dev/null;
then
    echo "Certificate for ${CERTCN} is valid for ${LIFETIME} days or more."
    exit 0

else
    echo "Renewing Cert for ${CERTCN}";
    tailscale cert --cert-file "${CERTFILE}" --key-file "${KEYFILE}" ${CERTCN}
fi
if [ -n "$PEM" ]; then
        echo "Combine ${CERTFILE} and ${KEYFILE} into ${PEM}"
        cat ${CERTFILE} ${KEYFILE} >> ${PEM}
fi
