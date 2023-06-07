#!/user/bin/env/bash
set -euxo pipefail
sudo apt-get purge -y docker-ce docker-ce-cli containerd.io
sudo rm -rf /var/lib/docker
