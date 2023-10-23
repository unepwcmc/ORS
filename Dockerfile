FROM --platform=linux/amd64 ubuntu:14.04.3

# https://stackoverflow.com/a/51803492/556780
SHELL [ "/bin/bash", "-l", "-c" ]

# https://stackoverflow.com/a/72000636/556780
# https://stackoverflow.com/questions/66803517/rails-error-cant-find-freedesktop-org-xml
# https://stackoverflow.com/questions/3116015/how-to-install-postgresqls-pg-gem-on-ubuntu
RUN apt update && \
    apt install -y wget curl git apt-transport-https ca-certificates shared-mime-info postgresql-client libpq5 libpq-dev && \
    update-ca-certificates

# NodeJS 0.10.25
RUN gpg --keyserver keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB && \
    wget https://nodejs.org/dist/v0.10.25/node-v0.10.25-linux-x64.tar.gz && \
    cd /usr/local && \
    tar --strip-components 1 -xzf /node-v0.10.25-linux-x64.tar.gz

RUN curl -sSLk https://get.rvm.io | bash
RUN rvm install 2.2.3

RUN mkdir /railsapp
WORKDIR /railsapp
RUN gem install bundler:1.17.3

COPY Gemfile /railsapp/Gemfile
COPY Gemfile.lock /railsapp/Gemfile.lock
RUN bundle install
COPY . /railsapp

EXPOSE 3000

# https://stackoverflow.com/questions/56586562/how-to-source-an-entry-point-script-with-docker
# https://stackoverflow.com/questions/56698195/docker-permanently-sourcing-file-when-building-an-image
ENTRYPOINT ["bin/entrypoint.sh"]

# Override in docker-compose.yml
CMD ["tail", "-f", "/dev/null"]
