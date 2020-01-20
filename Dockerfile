FROM alpine:latest
COPY . /opt/spandx/
ENV PACKAGES bash ruby ruby-bundler ruby-json ruby-rake git
RUN apk update && \
  apk add $PACKAGES && \
  gem build /opt/spandx/*.gemspec && \
  gem install /opt/spandx/*.gem && \
  mkdir -p tmp && \
  rm -fr /var/cache/apk/*
WORKDIR /scan
VOLUME /scan
CMD ["spandx"]
