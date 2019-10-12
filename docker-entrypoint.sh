#!/bin/sh

# Do not forget that reveal.js manage only the following
#   'index.html'
#   'css/**'
#   'js/**'
#   'lib/**'
#   'images/**'
#   'plugin/**'
#   '**.md'

cd  /slides

for folder  in $(find * -type d                 2> /dev/null | sort); do
    if [ -d "/reveal.js/${folder}"  ]; then
        target=$(cd "/reveal.js/${folder}" ; pwd)
        if [ "${target}" == "$(readlink -f ${target})" ]; then
            rm -rf  "/reveal.js/${folder}"
            ln -s   "/slides/${folder}" "/reveal.js/${folder}"
        fi
    else
        ln -s       "/slides/${folder}" "/reveal.js/${folder}"
    fi
done

for file    in $(find * -type f ! -name '.*'    2> /dev/null | sort); do
    if [ -f "/reveal.js/${file}"    ]; then
        target=$(cd $(dirname "/reveal.js/${file}") ; pwd)
        if [ "${target}" == "$(readlink -f ${target})" ]; then
            rm -f   "/reveal.js/${file}"
            ln -s   "/slides/${file}"    "/reveal.js/${file}"
        fi
    else
        ln -s       "/slides/${file}"    "/reveal.js/${file}"
    fi
done

cd /reveal.js

"$@"
