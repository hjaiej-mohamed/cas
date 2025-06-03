#!/bin/bash

if [[ -z "${CAS_KEYSTORE}" ]] ; then
  keystore="$PWD/thekeystore"
  echo -e "Generating keystore for CAS Server at ${keystore}"
  dname="${dname:-CN=cas.dnma.com,OU=DNMA,OU=FR,C=FR}"
  subjectAltName="${subjectAltName:-dns:cas.dnma.com,ip:my_ip_address}"
  [ -f "${keystore}" ] && rm "${keystore}"
  keytool -genkey -noprompt -alias cas -keyalg RSA \
    -keypass changeit -storepass changeit \
    -keystore "${keystore}" -dname "${dname}"
  [ -f "${keystore}" ] && echo "Created ${keystore}"
  export CAS_KEYSTORE="${keystore}"
else
  echo -e "Found existing CAS keystore at ${CAS_KEYSTORE}"
fi

docker stop casserver || true && docker rm casserver || true
echo -e "Mapping CAS keystore in Docker container to ${CAS_KEYSTORE}"
docker run --rm -d \
  --mount type=bind,source="${CAS_KEYSTORE}",target=/etc/cas/thekeystore \
  -p 8444:8443 --name casserver apereo/cas:6.5.4

docker logs -f casserver &
echo -e "Waiting for CAS..."
until curl -k -L --output /dev/null --silent --fail https://localhost:8444/cas/login; do
  echo -n .
  sleep 1
done
echo -e "\nCAS Server is running on port 8444"
echo -e "\n\nReady!"
