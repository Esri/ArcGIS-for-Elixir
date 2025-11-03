# ArcGIS for Elixir

Convenient access to Esri ArcGIS APIs for Elixir applications.

## Configuration

The behaviour of all functions which depend on information such as what the
ArcGIS Portal URL is can be defined by passing in variables as parameters.

However, a number of application-wide settings can be made in configuration
files such as `runtime.exs` under the `arcgis` config key. These include:

  * `portal`: An `ArcGIS.Portal` struct containing default settings such as
    URLs used when accessing an ArcGIS Portal.
  * `portal_client_id`: The string to pass as the client ID to ArcGIS REST APIs.
  * `default_query_timeout`: The default query timeout in millseconds.
  * `log_errors`: Boolean, whether or not to write errors via `Logger`.
  * `telemetry`: Boolean, whether or not to emit `:telemetry` messages.
