require 'spec_helper'

describe '## Nginx' do
    describe package('nginx'), :if => os[:family] == 'ubuntu' do
      it { should be_installed }
    end

    describe service('nginx'), :if => os[:family] == 'ubuntu' do
      it { should be_enabled }
      it { should be_running }
    end

    describe port(81) do
      it { should be_listening }
    end

    describe file('/etc/nginx/php.conf') do
      it { should exist }
      its(:content) { should match /\/opt\/php\/php-fpm\.sock/ }
    end

    describe file('/etc/nginx/sites-available/joomla.box.conf') do
      it { should exist }
      its(:content) { should match /joomla\.box/ }
    end

    describe file('/etc/nginx/sites-enabled/joomla.box.conf') do
      it { should be_symlink }
    end
end