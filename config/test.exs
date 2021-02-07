use Mix.Config

config :diff,
  registry: Diff.MockRegistry

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :diff, Diff.Repo,
  username: "postgres",
  password: "postgres",
  database: "diff_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :diff, Oban, queues: false, plugins: false

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :diff, DiffWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
