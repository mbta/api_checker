# ApiChecker

[![Build Status](https://semaphoreci.com/api/v1/mbta/api-checker/branches/master/badge.svg)](https://semaphoreci.com/mbta/api-checker)
[![codecov](https://codecov.io/gh/mbta/api-checker/branch/master/graph/badge.svg)](https://codecov.io/gh/mbta/api-checker)

An API checker that runs periodically and logs an error when and API's HTTP response is invalid.

## Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) for the overall architecture of the system.

## Summary

The V3 API (https://api-v3.mbta.com) replaced an existing API for the MBTA’s realtime data. A part of the existing API was a checker, running periodically, and e-mailing if there was a problem.

We want to replicate that for the new V3 API, using its public interface. This way, we can be sure that everything upstream of the API is working properly, and that clients have the data they expect.

## Goals

1. Log an error when the API fails to have expected data in it

2. Extensible enough to add new checks easily

3. Can schedule checks for particular times of day, days of the week

4. Can configure how stale the data can be


## Configuration

ApiChecker checks are run via a well defined and strict json configuration.

### Configuration Files

#### From files (recommended for dev and test)

A perodic task is configured by placing a json `array` of valid periodic task JSON objects in one of three files. Each file is loaded upon startup in `dev`, `test`, and `prod` environments, respectively:

+ `./priv/dev_checks_config.json`

+ `./priv/test_checks_config.json`

### Periodic Task JSON Object

A periodic task configures a schedule to run API `checks` in a given `frequency_in_seconds` against the provided `url` during the time of it's `time_ranges`.

An example of a periodic JSON object for configuration of a periodic task:

```json
{
    "name": "api-v3-predictions-1",
    "url": "https://api-v3.mbta.com/predictions?filter[route]=Red,Orange,Blue",
    "active": true,
    "frequency_in_seconds": 120,
    "time_ranges": [
        { "type": "weekly", "day": "SUN", "start": "05:59", "stop": "23:59" },
        { "type": "weekly", "day": "MON", "start": "05:59", "stop": "23:59" },
        { "type": "weekly", "day": "TUE", "start": "05:59", "stop": "23:59" },
        { "type": "weekly", "day": "WED", "start": "05:59", "stop": "23:59" },
        { "type": "weekly", "day": "THU", "start": "05:59", "stop": "23:59" },
        { "type": "weekly", "day": "FRI", "start": "05:59", "stop": "23:59" },
        { "type": "weekly", "day": "SAT", "start": "05:59", "stop": "23:59" }
    ],
    "checks": [
        { "type": "stale", "time_limit_in_seconds": 119 },
        { "type": "json", "keypath": ["data"], "expects": "not_empty" }
    ]
}
```

The `name` field is a unique identifier for a task. The `name` is the `task_name` in the logs and the key for looking up previous responses.

The `url` field is the url that will be checked for correct response JSON and/or stale data and must begin with `"http"` or `"https"`.

The `active` field is currently unused.

The `frequency_in_seconds` is the minimum desired frequency to run a check.

The `time_ranges` field is a json array of `time_range` configuration objects.

The `checks` field is a json array of `check` configuration objects.

### Weekly Time Range Configuration

Weekly times ranges are currently the only supported `time_range` type.

Weekly time range objects belong in an array on the `time_ranges` field of a periodic task configuration object.

An example of weekly `time_range` JSON object that runs on Sunday starting a `05:59` in the morning and stops at midnight:

```json
{ "type": "weekly", "day": "SUN", "start": "05:59", "stop": "23:59" }
```

The `type` field must be `"weekly"`.

The `day` field is must be one of `"MON"`, `"TUE"`, `"WED"`, `"THU"`, `"FRI"`, `"SAT"`, or `"SUN"`.

The `start` field is the start time for a check on the accompanying day; tasks will start running immediately after the start time of that day. Valid values are strings of military times between `"00:00"` and `"23:59"`. Note the `start_time` must be temporally before the `stop_time`.

The `stop` field is the stop time for a check on the accompanying day; tasks will not run after the stop time of that day. Valid values are strings of military times between `"00:00"` and `"23:59"`. Note the `stop_time` must be temporally after the `start_time`.


### Stale Data Check Configuration

A stale data check will log an error if the timestamp from the last time the data from the API changed is older than the `time_limit_in_seconds` allows and the current response body is the same as the old response body.

Stale data checks belong in an array on the `checks` field of a periodic task configuration object.

A typical example that configures a stale data check to only allow 119 second old data before an error is logged:

```json
{ "type": "stale", "time_limit_in_seconds": 119 },
```

The `type` field must be the string `"stale"` for a stale data check.

The `time_limit_in_seconds` field must be a positive integer.

### JSON Payload Check Configuration

A JSON payload check will log an error if an API responds with a JSON payload that does not meet the expectations of the check.

JSON payload checks belong in an array on the `checks` field of a periodic task configuration object.

A typical JSON payload check that checks a response for object's `"data"` field for an array that is not empty:

```json 
{ "type": "json", "keypath": ["data"], "expects": "not_empty" }
```

The `type` field for a JSON payload check must be `"json"`.

The `keypath` field is an array of key selectors that "select" values from nested json.

The `expects` field is a string that declaratively indicates what checks to
perform on the value selected by `keypath`. The allowed validators for
`expects` are: `"not_empty"` and `"jsonapi"`.

## Initial checks

+ https://api-v3.mbta.com/predictions?filter[route]=Red,Orange,Blue Every day, 6am to midnight Eastern
Run every 2 minutes
`data` should be non-empty

 + https://api-v3.mbta.com/vehicles/?route=Red,Orange,Blue
Every day, 6am to midnight Eastern
Run every 2 minutes
`data` should be non-empty

+ https://api-v3.mbta.com/predictions?filter%5Broute%5D=CR-Fairmount,CR-Fitchburg,CR-Worcester,CR-Franklin,CR-Greenbush,CR-Haverhill,CR-Kingston,CR-Lowell,CR-Middleborough,CR-Needham,CR-Newburyport,CR-Providence,CR-Foxboro
Weekdays, 6am to midnight
Weekends, 7am to midnight
Run every 2 minutes
`data` should be non-empty

+ https://api-v3.mbta.com/predictions/?filter%5Broute%5D=1
Every day, 6am to midnight
Run every 2 minutes
`data` should be non-empty

## Sample configuration from previous feed

https://mbtace.slack.com/files/U32MH8RCK/F9F0HTF96/apicalls.json
