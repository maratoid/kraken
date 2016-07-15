#/bin/bash

set -e

cd

if [[ -e /usr/bin/socat ]]; then
  exit 0
fi

wget -O - "$SOCAT_URL"
mv -n socat /usr/bin/socat
chmod +x /usr/bin/socat