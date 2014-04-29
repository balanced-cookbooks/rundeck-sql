rundeck-sql
==============

[![Build Status](https://travis-ci.org/balanced-cookbooks/rundeck-sql.png?branch=master)](https://travis-ci.org/balanced-cookbooks/rundeck-sql)

This cookbook creates a Rundeck project from a sql fabfile stored in git.
This allows you to use the same code for both local tasks and service-based
operations. This depends on the [Balanced version of the rundeck cookbook](https://github.com/balanced-cookbooks/rundeck).

Quick Start
-----------

Set the node attribute `['rundeck-sql']['repository']` to a Git URI and
`include_recipe 'rundeck-sql'`. This will create a project named "sql"
with one job for each task in your fabfile.

Attributes
----------

* `node['rundeck-sql']['repository']` – Git URI to clone from.
* `node['rundeck-sql']['revision']` – Git branch or tag to use. *(default: master)*
* `node['rundeck-sql']['version']` – Version of sql to install. *(default: latest)*

Resources
---------

### rundeck_sql_project

The `rundeck_sql_project` resource creates a Rundeck project based on a fabfile.

```ruby
rundeck_sql_project 'name' do
  sql_repository 'git://...'
  sql_revision 'release'
  sql_version '1.8.3'
end
```

* `sql_repository` – Git URI to clone from. *(default: node['rundeck-sql']['repository'], required)*
* `sql_revision` – Git branch or tag to use. *(default: node['rundeck-sql']['revision'])*
* `sql_version` – Version of sql to install. *(default: node['rundeck-sql']['version'])*
