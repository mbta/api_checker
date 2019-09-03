use Mix.Config

if Mix.env() == :test do
  config :logger, backends: []
end
