# ApiChecker Architecture

`prod_checks_config.json -> ApiChecker -> Splunk Cloud`

Overall, ApiChecker is made up of a few GenServers that run checks as
configured through `./priv/prod_checks_config.json`. The results of the checks
are logged. AWS pushes the logs to [Splunk
Cloud](https://www.splunk.com/en_us/products/splunk-cloud.html).

                                                 ./priv/prod_checks_config.json
                                                                │
                                                                │
                                                             checks
                                                                │
                                                                │
                                                                ▼
    ┌────────────────────────────┐               ┌────────────────────────────┐
    │ApiChecker.Scheduler        │◀───schedule───│ApiChecker.Schedule         │
    │                            │               │                            │
    │                            │◀──────┐       │                            │
    └────────────────────────────┘    consults   └────────────────────────────┘
                   │                    and      ┌────────────────────────────┐
                 check                updates    │ApiChecker.PreviousResponse │
                results                  └──────▶│                            │
                   │                             │                            │
                   ▼                             └────────────────────────────┘
    ┌────────────────────────────┐
    │Logs                        │
    │                            │
    │                            │
    └────────────────────────────┘

## ApiChecker.Schedule

Loads `ApiChecker.PeriodicTask` structs into memory as configured in
`./priv/prod_checks_config.json`. These `PeriodicTask` structs represent the
"schedule".

## ApiChecker.Scheduler

Consults the schedule, runs tasks due, and logs task results.
