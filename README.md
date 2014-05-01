rundeck-sql
==============

[![Build Status](https://travis-ci.org/balanced-cookbooks/rundeck-sql.png?branch=master)](https://travis-ci.org/balanced-cookbooks/rundeck-sql)

This cookbook creates Rundeck projects to execute SQL files to a database that are stored
in a particular structure on a git repository.

This depends on the [Balanced version of the rundeck cookbook](https://github.com/balanced-cookbooks/rundeck).

Quick Start
-----------

Set the node attribute `['rundeck-sql']['repository']` to a Git URI and
`include_recipe 'rundeck-sql'`. This will create two projects named "balanced"
and "precog" with one job for each SQL file and will schedule them based on
the folder they're included in.

Attributes
----------

* `node['rundeck-sql']['repository']` – Git URI to clone from.
* `node['rundeck-sql']['revision']` – Git branch or tag to use. *(default: master)*
* `node['rundeck-sql']['failure_email']` – An email to notify of a failed job execution
* `node['rundeck-sql']['failure_url']` – A webhook to invoke on a failed job execution

Resources
---------

### rundeck_sql_project

The `rundeck_sql_project` resource creates a Rundeck project based on specific naming
of folder structure to schedule.

It currently understands: `monthly` and `daily` and will schedule execution via
the templates located in `templates/default`.

```ruby
rundeck_sql_project 'name' do
  sql_repository 'git://...'
  sql_revision 'master'
  sql_globs ['monthly/*, 'daily/*']
end
```

* `sql_repository` – Git URI to clone from. *(default: node['rundeck-sql']['repository'], required)*
* `sql_revision` – Git branch or tag to use. *(default: node['rundeck-sql']['revision'])*
* `sql_globs` – Array of Glob expressions *required*
