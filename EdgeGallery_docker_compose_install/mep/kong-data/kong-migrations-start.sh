#!/bin/sh

set -e

loop=1
while [ $loop -le 60 ]
do
  set +e
  kong migrations bootstrap
  rc=$?
  set -e
  if [ $rc -eq 0 ]; then
    break
  else
    echo "loop $loop: waiting for postgres is ready"
    sleep 5
    loop=$((loop+1))
  fi
done
