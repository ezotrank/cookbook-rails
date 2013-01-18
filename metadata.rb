name "rails"

maintainer       "Maxim Kremenev"
maintainer_email "ezo@kremenev.com"
license          "All rights reserved"
description      "Upload and manage Ruby on Rails apps"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.0.1"

depends 'database'

supports "centos"

recommends "posgresql"
recommends "rvm"
recommends "nginx"
recommends "yum"
