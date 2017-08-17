#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
cd ${DIR}/../
ruby lib/ghettovcb-scheduler.rb
