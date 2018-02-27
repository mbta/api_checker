# ApiChecker

An API checker that runs periodically and logs an error when API response is invalid.

## Summary

The V3 API (https://api-v3.mbta.com) replaced an existing API for the MBTA’s realtime data. A part of the existing API was a checker, running periodically, and e-mailing if there was a problem.

We want to replicate that for the new V3 API, using its public interface. This way, we can be sure that everything upstream of the API is working properly, and that clients have the data they expect.

## Goals

1. Log an error when the API fails to have expected data in it

2. Extensible enough to add new checks easily

3. Can schedule checks for particular times of day, days of the week

4. Can configure how stale the data can be

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