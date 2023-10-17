FROM --platform=linux/amd64 ruby:2.2.3

# NodeJS 0.10.25
RUN wget https://nodejs.org/dist/v0.10.25/node-v0.10.25-linux-x64.tar.gz && \
    cd /usr/local && \
    tar --strip-components 1 -xzf /node-v0.10.25-linux-x64.tar.gz

RUN mkdir /railsapp
WORKDIR /railsapp
RUN gem install bundler:1.17.3

COPY Gemfile /railsapp/Gemfile
COPY Gemfile.lock /railsapp/Gemfile.lock
RUN bundle install
COPY . /railsapp

EXPOSE 3000

# CMD ["rails", "server", "-b", "0.0.0.0"]
CMD ["tail", "-f", "/dev/null"]
