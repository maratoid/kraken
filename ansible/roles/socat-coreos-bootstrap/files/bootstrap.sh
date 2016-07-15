#/bin/bash

set -e

cd

if [[ -e /usr/bin/socat ]]; then
  exit 0
fi

wget "$SOCAT_URL"
mv ./socat /usr/bin/socat
chmod +x /usr/bin/socat