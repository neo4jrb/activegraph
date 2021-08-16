FROM ruby:latest

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y locales && \
    apt-get install -y build-essential libjson-c-dev && \
    apt-get clean -y
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen

WORKDIR /usr/src/app/

# Seabolt install. Needed for bolt driver interface
ADD https://github.com/neo4j-drivers/seabolt/releases/download/v1.7.4/seabolt-1.7.4-Linux-ubuntu-18.04.deb /usr
RUN dpkg -i /usr/seabolt-1.7.4-Linux-ubuntu-18.04.deb
RUN rm /usr/seabolt-1.7.4-Linux-ubuntu-18.04.deb

RUN gem install bundler -v '~> 2'
COPY Gemfile* activegraph.gemspec ./
COPY lib/active_graph/version.rb ./lib/active_graph/
RUN bundle install

ADD . ./

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_ALL en_US.UTF-8
