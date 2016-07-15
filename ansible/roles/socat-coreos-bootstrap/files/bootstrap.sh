#/bin/bash

set -e

cd

if [[ -e /usr/bin/socat ]]; then
  exit 0
fi

wget "$SOCAT_URL"
mv ./socat /opt/bin/socat
chmod 755 /opt/bin/socat