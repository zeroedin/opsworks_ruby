# frozen_string_literal: true

require 'spec_helper'

describe 'opsworks_ruby::setup' do
  describe package('ruby2.6') do
    it { should be_installed }
  end

  describe package('libsqlite3-dev') do
    it { should be_installed }
  end

  describe package('git') do
    it { should be_installed }
  end

  describe package('nginx') do
    it { should_not be_installed }
  end

  describe package('nginx-extras') do
    it { should be_installed }
  end  

  describe package('passenger') do
    it { should be_installed }
  end

  describe package('libxml2-dev') do
    it { should be_installed }
  end

  describe package('tzdata') do
    it { should be_installed }
  end

  describe package('zlib1g-dev') do
    it { should be_installed }
  end

  describe file('/usr/local/bin/bundle') do
    it { should be_symlink }
  end
end

describe 'opsworks_ruby::configure' do
  context 'webserver' do
    describe file('/etc/logrotate.d/dummy_project-nginx-production') do
      its(:content) do
        should include '"/var/log/nginx/dummy-project.example.com.access.log" ' \
                       '"/var/log/nginx/dummy-project.example.com.error.log" {'
      end
      its(:content) { should include '  daily' }
      its(:content) { should include '  rotate 30' }
      its(:content) { should include '  missingok' }
      its(:content) { should include '  compress' }
      its(:content) { should include '  delaycompress' }
      its(:content) { should include '  notifempty' }
      its(:content) { should include '  copytruncate' }
      its(:content) { should include '  sharedscripts' }
    end

    describe file('/etc/nginx/ssl/dummy-project.example.com.key') do
      its(:content) { should include '-----BEGIN RSA PRIVATE KEY-----' }
    end

    describe file('/etc/nginx/ssl/dummy-project.example.com.crt') do
      its(:content) { should include '-----BEGIN CERTIFICATE-----' }
    end

    describe file('/etc/nginx/ssl/dummy-project.example.com.ca') do
      its(:content) { should include '-----BEGIN CERTIFICATE-----' }
    end

    describe file('/etc/nginx/sites-enabled/dummy_project.conf') do
      it { should be_file }
    end

    describe file('/etc/nginx/sites-available/dummy_project.conf') do
      its(:content) { should include 'passenger_enabled on;' }
      its(:content) { should include 'root /srv/www/dummy_project/current/public;' }
    end
  end

  context 'appserver' do
    describe file('/etc/nginx/passenger.conf') do
      its(:content) { should include 'passenger_root /usr/lib/ruby/vendor_ruby/phusion_passenger/locations.ini;' }
      its(:content) { should include 'passenger_ruby /usr/bin/passenger_free_ruby;' }
    end

    describe command('/usr/bin/passenger-config validate-install --auto') do
      its(:stdout) { should match(/Everything looks good/)}
    end

    describe command('passenger-memory-stats') do
      its(:exit_status) { should eq 0 }
    end

    describe command('passenger-status') do
      its(:stdout) { should match('Phusion_Passenger/6.0.2')}
      its(:stdout) { should match('nginx/1.15.8')}
    end

    describe command('nginx -t') do
      its(:exit_status) { should eq 0 }
      its(:stderr) { should contain("nginx: the configuration file /etc/nginx/nginx.conf syntax is ok\n") }
      its(:stderr) { should contain("nginx: configuration file /etc/nginx/nginx.conf test is successful\n") }
    end
  end

  context 'framework' do
    describe file('/etc/logrotate.d/dummy_project-rails-production') do
      its(:content) { should include '"/srv/www/dummy_project/shared/log/*.log" {' }
      its(:content) { should include '  daily' }
      its(:content) { should include '  rotate 30' }
      its(:content) { should include '  missingok' }
      its(:content) { should include '  compress' }
      its(:content) { should include '  delaycompress' }
      its(:content) { should include '  notifempty' }
      its(:content) { should include '  copytruncate' }
      its(:content) { should include '  sharedscripts' }
    end

    describe file('/srv/www/dummy_project/current/config/database.yml') do
      its(:content) { should include 'adapter: sqlite3' }
    end
  end
end

describe 'opsworks_ruby::deploy' do
  context 'source' do
    describe file('/tmp/ssh-git-wrapper.sh') do
      its(:content) { should include 'exec ssh -o UserKnownHostsFile=/dev/null' }
    end

    describe file('/srv/www/dummy_project/current/.git') do
      it { should_not exist }
    end
  end

  context 'webserver' do
    describe service('nginx') do
      it { should be_running }
    end
  end

  context 'appserver' do
    describe command('nginx -t') do
      its(:exit_status) { should eq 0 }
      its(:stderr) { should contain("nginx: the configuration file /etc/nginx/nginx.conf syntax is ok\n") }
      its(:stderr) { should contain("nginx: configuration file /etc/nginx/nginx.conf test is successful\n") }
    end
  end

  context 'framework' do
    describe command('ls -1 /srv/www/dummy_project/current/public/assets/application-*.css*') do
      its(:stdout) { should match(/application-[0-9a-f]{64}.css/) }
      its(:stdout) { should match(/application-[0-9a-f]{64}.css.gz/) }
    end

    describe command('ls -1 /srv/www/dummy_project/current/public/test/application-*.css*') do
      its(:stdout) { should match(/application-[0-9a-f]{64}.css/) }
      its(:stdout) { should match(/application-[0-9a-f]{64}.css.gz/) }
    end
  end
end
