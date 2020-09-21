#!/bin/bash

CLIDIR=$PWD

export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

go version
if [ $? -ne 0 ]; then

  cd /tmp/
  wget -N https://dl.google.com/go/go1.13.3.linux-amd64.tar.gz
  tar -xvf go1.13.3.linux-amd64.tar.gz
  mv go /usr/local
fi

cd $CLIDIR

go install
