name "rails"

maintainer       "Maxim Kremenev"
maintainer_email "ezo@kremenev.com"
license          "All rights reserved"
description      "Upload and manage Ruby on Rails apps"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.0.3"

depends 'database'
depends 'postgresql'
depends 'nginx'

supports "centos"

recommends "rvm"
recommends "yum"
