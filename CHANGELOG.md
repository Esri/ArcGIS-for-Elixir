# Changelog

All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v1.0.0

* BREAKING CHANGES (and how to migrate from earlier versions)
  * The `selector` option was removed from `Portal.post` and `Portal.get`. This was seldom used, and 
    only made the code more complex and brittle. To migrate uses of `selector`, pattern match on the return value 
    from `Portal.get` or `Portal.put` to get the same effect.
  * `form_data` passed to `ArcGIS.Feature.Service.post/4` and `ArcGIS.Portal.post/4` must now be a map.
    Previously, keyword lists were also accepted, but this was rarely used and only complicated the code base.
    To migrate, simply move from a keyword list to a map for any `form_data`.
  * Entries in `form_data` override duplicate entries in `options`. This prevents behaviour such as a default `1=1`
    where clause from overriding a where clause passed in as form data.
  * `ArcGIS.User.generate_token` accepts `%ArcGIS.Portal{}` as the first parameter, rather than the third.
    This matches the rest of the library where the portal struct is always the first parameter.
* Improvements
  * Added `ArcGIS.Feature.delete/4`, providing bulk delete with a where clause.
  * Increased API consistency (e.g. `%ArcGIS.Portal` is always the first parameter in a function)
  * Some ArcGIS errors have a description, but no message. In those cases, the description is now
    used as the message.
* Janitorial
  * Updated typespecs for accuracy

## v0.2.1

* Fixes
  * `ArcGIS.Portal.default_portal` returns an `%ArcGIS.Portal{}` struct in all cases, without `:ok` tuple wrapping.
    The typespec already noted this, but the function implementation di dnot follow that typing.

## v0.2.0

* Improvements
  * Add a `schema` field to `ArcGIS.Feature.Service`
  * Add `ArcGIS.Feature.Service.with_schema/1` to fetch and store a feature service schema
  * Support ArcGIS Enterprise
  * Add `order_by` to the list of supported query parameters
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
