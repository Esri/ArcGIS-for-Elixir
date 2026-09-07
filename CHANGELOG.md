# Changelog

All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v0.2.0

* Improvements
  * Add a `schema` field to `ArcGIS.Feature.Service`
  * Add `ArcGIS.Feature.Service.with_schema/1` to fetch and store a feature service schema
  * Support ArcGIS Enterprise
* Fixes
  * Fix service URL caching when the `verify_tls` is false
* Janitorial
  * More documentation and some improved typing
  
## v0.1.1

* Fixes
  * Always provide a referer and clientID when requesting a token

## v0.1.0

Initial release with support for:

* ArcGIS Portal
  * Both ArcGIS Online and Enterprise are supported
  * Service discovery via the `self` endpoint
  * HTTP GET and POST requests against a portal
  * Portal item queries
* Feature services
  * Create, update, and delete feature services
  * Create, update, delete, and query features
  * Fetch the schema of a feature service
