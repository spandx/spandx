FROM alpine:latest
WORKDIR /scan
ENV PACKAGES build-base cmake bash ruby ruby-dev ruby-bundler ruby-json ruby-rake git libxml2-dev openssl-dev
COPY . /opt/spandx/
RUN apk update && \
  apk add $PACKAGES && \
  gem update --system && \
  cd /opt/spandx/ && \
  gem build *.gemspec && \
  gem install --no-document *.gem && \
  rm -fr /var/cache/apk/*
VOLUME /scan
CMD ["spandx"]
