FROM hexpm/elixir:1.11.0-erlang-21.3.8.21-alpine-3.13.1 as builder

WORKDIR /root

# Install Hex+Rebar
RUN mix local.hex --force && \
  mix local.rebar --force

# Install git
RUN apk --update add git make

ENV MIX_ENV=prod

ADD . .

WORKDIR /root

# Generates a compiled prod release using distillery.
RUN elixir --erl "-smp enable" /usr/local/bin/mix do deps.get --only prod, compile, distillery.release --verbose

# Second stage: uses the built .tgz to get the files over
FROM alpine:3.13.1

RUN apk add --update libssl1.1 ncurses-libs bash \
	&& rm -rf /var/cache/apk

# Set environment
ENV MIX_ENV=prod TERM=xterm LANG=C.UTF-8 REPLACE_OS_VARS=true

WORKDIR /root/

COPY --from=builder /root/_build/prod/rel /root/rel

# Set default API checker configuration
ENV API_CHECKER_CONFIGURATION=[]

# Ensure SSL support is enabled
RUN /root/rel/api_checker/bin/api_checker eval ":crypto.supports()"

CMD ["/root/rel/api_checker/bin/api_checker", "foreground"]
