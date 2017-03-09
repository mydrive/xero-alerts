FROM ruby:2.4.0-alpine

RUN apk --no-cache update && \
  apk --no-cache add python py-pip py-setuptools ca-certificates curl groff less && \
  pip --no-cache-dir install awscli

RUN apk --no-cache update && \
  apk --no-cache add git build-base libcurl curl-dev && \
  rm -rf /var/cache/apk/*

ADD Gemfile Gemfile.lock run.sh xero-alert.rb ./

RUN bundle install

CMD [ "./run.sh" ] 

