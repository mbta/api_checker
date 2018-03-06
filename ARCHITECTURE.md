# ApiChecker Architecture

`API_CHECK_CONFIGURATION Environment Variable -> ApiChecker -> Splunk Cloud`

Overall, ApiChecker is made up of a few GenServers that run checks as
configured through the `API_CHECK_CONFIGURATION` environment variable. The
results of the checks are logged. AWS pushes the logs to [Splunk
Cloud](https://www.splunk.com/en_us/products/splunk-cloud.html).

    API_CHECK_CONFIGURATION=[...] (ENV VAR)
                   │
                   │
               schedule
                   │
                   │
                   ▼
    ┌────────────────────────────┐              ┌────────────────────────────┐
    │ApiChecker.Scheduler        │    consults  │ApiChecker.PreviousResponse │
    │                            │◀─────and ───▶│                            │
    │                            │    updates   │                            │
    └────────────────────────────┘              └────────────────────────────┘
                   │
                 check
                results
                   │
                   ▼
    ┌────────────────────────────┐
    │Logs                        │
    │                            │
    │                            │
    └────────────────────────────┘

## API_CHECK_CONFIGURATION Environment Variable

Loads `ApiChecker.PeriodicTask` structs into memory as configured in
`API_CHECK_CONFIGURATION` environment variable. These `PeriodicTask` structs
represent the "schedule".

## ApiChecker.Scheduler

Consults the schedule, runs tasks due, and logs task results.

## ApiChecker.PreviousResponse

Keeps track of the previous responses for each `ApiChecker.PeriodicTask` struct.
