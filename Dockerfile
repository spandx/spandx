FROM alpine:latest
COPY . /opt/spandx/
ENV PACKAGES build-base cmake bash ruby ruby-dev ruby-bundler ruby-json ruby-rake git libxml2-dev openssl-dev
RUN apk update && \
  apk add $PACKAGES && \
  gem build /opt/spandx/*.gemspec && \
  gem install /opt/spandx/*.gem && \
  mkdir -p tmp && \
  rm -fr /var/cache/apk/*
WORKDIR /scan
VOLUME /scan
CMD ["spandx"]
