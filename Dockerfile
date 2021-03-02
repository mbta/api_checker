FROM hexpm/elixir:1.11.3-erlang-23.2.6-alpine-3.13.2 as builder

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
RUN mix do deps.get --only prod, compile, distillery.release --verbose

# Second stage: copies the release over
FROM alpine:3.13.2

RUN apk add --update libssl1.1 ncurses-libs bash dumb-init \
	&& rm -rf /var/cache/apk

# Set environment
ENV MIX_ENV=prod TERM=xterm LANG=C.UTF-8 REPLACE_OS_VARS=true

RUN addgroup -S api_checker && adduser -S -G api_checker api_checker
USER api_checker
WORKDIR /home/api_checker

COPY --from=builder --chown=api_checker:api_checker /root/_build/prod/rel/api_checker /home/api_checker

# Set default API checker configuration
ENV API_CHECKER_CONFIGURATION=[]

# Ensure SSL support is enabled
RUN /home/api_checker/bin/api_checker eval ":crypto.supports()"

ENTRYPOINT ["/usr/bin/dumb-init", "--"]

HEALTHCHECK CMD ["/home/api_checker/bin/api_checker", "ping"]
CMD ["/home/api_checker/bin/api_checker", "foreground"]
