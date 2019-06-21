################################################################################
#                               BUILDER                                        #
################################################################################
FROM    alpine:3.9           as builder

ARG proxy

ENV HTTP_PROXY                  ${proxy}
ENV HTTPS_PROXY                 ${proxy}

ENV http_proxy                  ${proxy}
ENV https_proxy                 ${proxy}
ENV GIT_HTTP_PROXY_AUTHMETHOD   basic

RUN     apk update                                                              &&  \
        apk --no-cache  --update    add     --virtual .build-deps   git         &&  \
        git config  --global http.proxy     "${proxy}"                          &&  \
        git config  --global https.proxy    "${proxy}"                          &&  \
        git config  --global http.sslVerify "false"                             &&  \
        git clone   https://github.com/hakimel/reveal.js.git    /reveal.js      &&  \
        rm  -rf     /reveal.js/.git /root/.gitconfig                            &&  \
        apk del     .build-deps

RUN     apk --no-cache  --update    add     nodejs  nodejs-npm

WORKDIR /reveal.js
RUN     npm     install -D /reveal.js   && npm  audit   fix                     &&  \
        sed -i 's^open: true^open: false^'              gruntfile.js            &&  \
        sed -i 's^livereload: true^livereload: false^'  gruntfile.js

# install plugin
WORKDIR /reveal.js/plugin
RUN     apk --no-cache  --update    add     --virtual .build-deps   curl            \
                                                                                &&  \
        mkdir   -p  tmp                                                             \
                                                                                &&  \
        rm      -rf tmp/*   &&  mkdir   -p menu                                 &&  \
        curl    'https://github.com/denehyg/reveal.js-menu/tarball/master'          \
                    --insecure  -sS -L  --output    menu.tar.gz                 &&  \
        tar     xfz menu.tar.gz         -C  'tmp'   --strip-components=1        &&  \
        find    tmp/*   -maxdepth 0     -name ".*"  -exec rm -rf {} \;          &&  \
        cp      -rf tmp/*                           menu/                           \
                                                                                &&  \
        rm      -rf tmp/*   &&  mkdir   -p toolbar                              &&  \
        curl    'https://github.com/denehyg/reveal.js-toolbar/tarball/master'       \
                    --insecure  -sS -L  --output    toolbar.tar.gz              &&  \
        tar     xfz toolbar.tar.gz      -C  'tmp'   --strip-components=1        &&  \
        find    tmp/*   -maxdepth 0     -name ".*"  -exec rm -rf {} \;          &&  \
        cp      -rf tmp/*                           toolbar/                        \
                                                                                &&  \
        rm      -rf tmp/*   &&  mkdir   -p math                                 &&  \
        curl    'https://github.com/mathjax/MathJax/tarball/master'                 \
                    --insecure  -sS -L  --output    mathjax.tar.gz              &&  \
        tar     xfz mathjax.tar.gz      -C  'tmp'   --strip-components=1        &&  \
        find    tmp/*   -maxdepth 0     -name ".*"  -exec rm -rf {} \;          &&  \
        rm      -rf tmp/test    tmp/docs                                        &&  \
        cp      -rf tmp/*                           math/                       &&  \
        sed     -i "s^var mathjax = .*;^var mathjax = '/plugin/math/MathJax.js';^"  \
                    math/math.js                                                &&  \
                                                                                    \
        rm      -rf tmp *.tar.gz                                                &&  \
        apk del     .build-deps

################################################################################
#                               RUNNER                                         #
################################################################################
FROM    alpine:3.9          as  runner

RUN     apk update                                                              &&  \
        apk --no-cache      --update    add     nodejs  nodejs-npm

COPY    --from=builder  /reveal.js/             /reveal.js
COPY                     docker-entrypoint.sh   /
RUN     chmod   755     /docker-entrypoint.sh

WORKDIR /slides

RUN     mv              /reveal.js/index.html   /slides                         &&  \
        ln      -s      /slides/index.html      /reveal.js/

VOLUME  /slides
EXPOSE  8000

ENTRYPOINT  [ "/docker-entrypoint.sh" ]
CMD         [ "npm", "start" ]

# docker build --build-arg proxy='http://${ID}:${PASWWORD}@${PROXY_HOST}:${PROXY_PORT}/' --tag reveal.js:3.8.0 .
# docker run   --rm -it  --publish 8000:8000    --volume $PWD:/slides:ro                       reveal.js:3.8.0
