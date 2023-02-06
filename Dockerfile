ARG ELIXIR_VERSION=1.14.3
ARG ERLANG_VERSION=25.2.2
ARG ALPINE_VERSION=3.17.0

FROM hexpm/elixir:${ELIXIR_VERSION}-erlang-${ERLANG_VERSION}-alpine-${ALPINE_VERSION} as builder

WORKDIR /root

# Install Hex+Rebar
RUN mix local.hex --force && \
  mix local.rebar --force

# Install git
RUN apk --update add git make

ENV MIX_ENV=prod

WORKDIR /root

ADD config config
ADD mix.* ./

# Get dependencies
RUN mix do deps.get --only prod, deps.compile

ADD . .

# Generates a compiled prod release
RUN mix release

# Second stage: copies the release over
FROM alpine:${ALPINE_VERSION}

RUN apk add --update libssl1.1 libstdc++ libgcc ncurses-libs bash dumb-init \
	&& rm -rf /var/cache/apk

# Set environment
ENV MIX_ENV=prod TERM=xterm LANG=C.UTF-8

RUN addgroup -S api_checker && adduser -S -G api_checker api_checker
USER api_checker
WORKDIR /home/api_checker

COPY --from=builder --chown=api_checker:api_checker /root/_build/prod/rel/api_checker /home/api_checker

# Set default API checker configuration
ENV API_CHECKER_CONFIGURATION=[]

# Ensure SSL support is enabled
RUN /home/api_checker/bin/api_checker eval ":crypto.supports()"

ENTRYPOINT ["/usr/bin/dumb-init", "--"]

HEALTHCHECK CMD ["/home/api_checker/bin/api_checker", "rpc", "1 + 1"]
CMD ["/home/api_checker/bin/api_checker", "start"]
