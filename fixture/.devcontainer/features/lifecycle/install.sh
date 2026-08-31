#!/bin/sh
mkdir -p /usr/local/lib/lifecycle-dropins
cp dropins/00-hello.sh /usr/local/lib/lifecycle-dropins/00-hello.sh
chmod +x /usr/local/lib/lifecycle-dropins/00-hello.sh
cp lifecycle-runner /usr/local/bin/lifecycle-runner
chmod +x /usr/local/bin/lifecycle-runner
