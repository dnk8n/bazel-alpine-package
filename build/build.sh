#!/usr/bin/env bash

docker_build() {
  context=$1
  options=$2
#  while ! pgrep -f docker >>/dev/null
#    do echo "waiting for docker daemon" && sleep 1
#  done
  sleep 60
  cd ${context}
  docker build ${options} .
}

"$@"
