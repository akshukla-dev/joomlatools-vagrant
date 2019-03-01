# encoding: utf-8
require 'spec_helper'

describe '## Command Line Tools' do
    let(:sudo_options) { '-u vagrant -i' } # Simulate a login as the user, so that the PATH variable is loaded

    describe command('echo $JOOMLATOOLS_BOX') do
      its(:stdout) { should match /\d\.\d+\.\d+/ }
    end

    describe command('id') do
       its(:stdout) { should match /vagrant/ }
    end

    describe user('vagrant') do
      it { should have_login_shell '/bin/bash' }
    end

    describe command('phpmetrics --version') do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match'PhpMetrics v' }
    end

    describe command('git ftp --version') do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match 'git-ftp version' }
    end

    describe package('httpie') do
      it { should be_installed }
    end

    describe command('ls -lah /home/vagrant/.gem/ruby/2.5.0/gems/') do
       its(:stdout) { should match /capistrano-3\.\d+\.\d+/ }
       its(:stdout) { should match /sass-\d+\.\d+\.\d+/ }
       its(:stdout) { should match /compass-core-\d+\.\d+\.\d+/ }
       its(:stdout) { should match /bundler-\d+\.\d+\.\d+/ }
    end

    describe package('git') do
       it { should be_installed }
    end
end