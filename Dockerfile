FROM ruby:2.3.1-alpine

MAINTAiNER lacienator@gmail.com

ADD . /code

WORKDIR /code

RUN bundle install

EXPOSE 6666

CMD ["ruby", "bin/raff.thor", "start"]
