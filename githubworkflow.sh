#!/bin/bash

#
# Detects if system is macOS
#


cd ~
git clone git://github.com/sstephenson/rbenv.git .rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
exec $SHELL

git clone git://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc
exec $SHELL

# Now install Ruby v2.3.1:
sudo apt-get install -y libreadline-dev
rbenv install 2.3.1

#  Install Postgres
sudo apt-get install postgresql \
                        postgresql-contrib \
                        libpq-dev


export PATH=/usr/bin:$PATH
sudo -u postgres createuser --superuser $USER
sudo -u postgres createdb $USER
psql 
CREATE ROLE itig WITH CREATEDB PASSWORD 'd872$dh' LOGIN;

sudo apt-get install ghostscript \
                       imagemagick \
                       libmagickwand-dev \
                       libmagic-dev \
                       python-pygments

gem install overcommit
rbenv rehash
overcommit --install

gem install bundler
rbenv rehash
bundle install --without production replica staging

bundle exec rake db:create
bundle exec rake db:populate



msg "You should now be able to launch the server with bundle exec rails s"
verbose "Doubtfire should be successfuly Installed!"
