#START
#!/bin/sh

yum -y install openssl-devel 2> openssldevel_error.txt
#yum -y install openssl 2> openssl_error.txt

wget ftp://ftp.ruby-lang.org/pub/ruby/1.8/ruby-1.8.7.tar.gz 2> wget_erro_r.txt
gunzip ruby-1.8.7.tar.gz 2> gunzip_error_r.txt
tar xvf ruby-1.8.7.tar 2> tar_error_r.txt
cd ruby-1.8.7 
./configure -prefix=/usr/local  2> configure_error_r.txt
make 2> make_error.txt
make install 2> make_install_error.txt


#Append to PATH:
export PATH=/usr/local/bin/ruby:$PATH
cd ~

#2) Grab the latest rubygems and gunzip / tar it then run
wget http://rubyforge.org/frs/download.php/74388/rubygems-1.6.1.tgz 2> wget_error_rg.txt
gunzip rubygems-1.6.1.tgz 2> gunzip_error_rg.txt
tar -xvf rubygems-1.6.1.tar 2> tar_error_rg.txt
cd rubygems-1.6.1
ruby ./setup.rb 2> setup_rg.txt
cd ~

export RUBYOPT=rubygems


#3)
gem install rails
gem install statsample -v 0.16.0 --source http://rubygems.org
gem install statistics2 --source http://rubygems.org
gem install activesupport --source http://rubygems.org

#4) 
gem install crack 
gem install rest-client
gem install net-ssh
gem install net-scp
gem install simplehttp
gem install i18n


#DONE
