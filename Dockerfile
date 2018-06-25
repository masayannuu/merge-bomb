FROM ruby:2.5.0
ENV LANG C.UTF-8
ENV APP_ROOT /app
ENV ENTRYKIT_VERSION 0.4.0
ENV DOCKERIZE_VERSION v0.3.0

WORKDIR $APP_ROOT

RUN apt-get update && \
    apt-get install -y nodejs \
                       mysql-client \
                       --no-install-recommends && \
    rm -rf /var/lib/apt/lists/* && \
    # bundle setting
    bundle config --global build.nokogiri --use-system-libraries && \
    bundle config --global jobs $(nproc) && \
    # entrykit
    wget https://github.com/progrium/entrykit/releases/download/v${ENTRYKIT_VERSION}/entrykit_${ENTRYKIT_VERSION}_Linux_x86_64.tgz && \
    tar -xvzf entrykit_${ENTRYKIT_VERSION}_Linux_x86_64.tgz && \
    rm entrykit_${ENTRYKIT_VERSION}_Linux_x86_64.tgz && \
    mv entrykit /bin/entrykit && \
    chmod +x /bin/entrykit && \
    entrykit --symlink && \
    # dockerize
    wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz && \
    tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz && \
    rm dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz &&\
    # sslkey gen
    cd /root && \
    openssl genrsa 2048 > server.key && \
    yes '' | openssl req -new -key server.key > server.csr && \
    openssl x509 -days 3650 -req -signkey server.key < server.csr > server.crt

ENTRYPOINT [ \
  "prehook", "ruby -v", "--", \
  "prehook", "bundle install -j3 --quiet --path vendor/bundle", "--", \
  "prehook", "dockerize -timeout 60s -wait tcp://mysql:3306", "--"]