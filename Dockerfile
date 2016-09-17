FROM ruby:2.3.1-alpine

ADD . /code

WORKDIR /code

RUN bundle install

EXPOSE 6666

CMD ["ruby", "bin/raff.thor", "start"]
