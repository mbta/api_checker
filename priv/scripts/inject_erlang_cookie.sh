#!/bin/bash

cat ./rel/config.exs | sed "s/{ERLANG_COOKIE}/`cat erlang.secret.cookie`/g" > ./rel/config.exs
