# -*- ruby -*-
$:.unshift(File.dirname(__FILE__) + "/lib")

require 'rubygems'
require 'hoe'
require 'circuit_breaker'

hoe = Hoe.spec 'circuit_breaker' do |p|
  self.rubyforge_name = 'circuit-breaker'
  developer('Will Sargent', 'will.sargent@gmail.com')
  
  p.remote_rdoc_dir = '' # Release to root only one project

  p.extra_deps << [ 'rubyist-aasm' ]
  p.extra_dev_deps << [ 'rspec' ]
  File.open(File.join(File.dirname(__FILE__), 'VERSION'), 'w') do |file|
    file.puts CircuitBreaker::VERSION
  end
end

begin
  require 'jeweler'
  Jeweler::Tasks.new(hoe.spec)
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

