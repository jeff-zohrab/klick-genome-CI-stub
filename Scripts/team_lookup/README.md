# Team lookup

Lookup team member information from google sheets,
using the Google Ruby client.

The sheet to be consulted is hardcoded in config.yml.

## Environment setup

```
bundle install
```

or install the gems in the gemfile:

```
rake gem:install
```

## Config

Put `client_secrets.json` in this directory (it's in .gitignore)

## Usage

1. Authorize: `rake sheets:authorize` and follow the prompt.  This
generates `token.yml`, used for subsequent requests.

2. Test: `rake sheets:test` dumps some data from the google sheet.
Useful for checking the connection and authorization.

## Notes

* Google's quickstart: https://developers.google.com/sheets/api/quickstart/ruby
