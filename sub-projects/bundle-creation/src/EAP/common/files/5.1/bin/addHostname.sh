if ! grep -q `hostname` /etc/hosts; then echo 127.0.0.1 `hostname` >> /etc/hosts; fi
