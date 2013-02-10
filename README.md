Description
===========

This cookbook is used to configure and add resource for Rails app.

Requirements
============

Platforms
---------

The following platforms are supported by this cookbook, meaning that the recipes run on these platforms without error.

* Debian family (Debian, Ubuntu etc)
* Red Hat family (Redhat, CentOS, Oracle etc)

Opscode Cookbooks
-----------------

* [postgresql](https://github.com/opscode-cookbooks/postgresql) or
  [mysql](https://github.com/opscode-cookbooks/mysql)
  
Included cookbooks:
-------------------
* database
* postgresql
* mysql
* nginx
* rvm

Attributes
==========

Node
----

    "rails_apps": [
        { "name": "app1", "env": ["production"] },
		{ "name": "app2", "env": ["production", "staging"] }
    ]

Where:

* `name` : is rails app data bags name
* `env`  : array of rails app environments needed to install in this node

DataBags:
---------

    {
      "id": "app1",
      "database": "postgresql",
      "environments": [
	    {
	      "folder": "/var/www/app1_site",
	      "name": "production",
	      "database": {
		    "adapter":  "postgresql",
			"name":     "app1_databse",
			"password": "password",
			"username": "app1_username"
			},
			"ruby_version": "ruby-1.9.3-p327",
			"unicorn_workers": 1,
			"urls": [
			  "app1.example.com"
			],
			"user": {
			  "login": "app1user",
			  "ssh_keys": [
		      "ssh-rsa cLBSlmogU1S92AnFWrUqXJt0wAGx0zuFNN5KdaskdaskdaskdjsakdjaskdjaslkdjadkashjdksajdsjadkjdhasjdhaskjdhkjdhasjkdhsajkdhjkHJKHDSAKJHDJKSAHDKJSAHDdhsajdhask user@localhost",
			  "ssh-rsa cLBSlmogU1S92AnFWrUqXJt0wAGx0zuFNN5KdaskdaskdaskdjsakdjaskdjaslkdjadkashjdksajdsjadkjdhasjdhaskjdhkjdhasjkdhsajkdhjkHJKHDSAKJHDJKSAHDKJSAHDdhsajdhask user2@localhost"
			  ]
			}
		}
      ]
    }

Where:

* `"id": "app1"` - rails app name, must be unique
* `"database": "postgresql"` - database backend. Can be "posgresql" or "mysql"
* `"environments": []` - all rails environments what you want to describe
* `"folder": "/var/www/app1_site"` - main folder. When app will be
  stored, in this folder after execute this cookbook will be create
  folder 'shared' and in the future have a folder named `current`
* `"name": "production"` - name of environment
* `"database": {}` - describe database config
* `"ruby_version": "ruby-1.9.3-p327"` - what version ruby do you want
  install for this app
* `"unicorn_workers": 1` - number of uniconr workers
* `"urls": ["app1.example.com"]` - hostames. It's will be append to
  nginx config
* `"user": {}` - describe user attributes for app
  

Usage
=====
