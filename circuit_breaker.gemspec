(in C:/Users/wsargent/work/circuit_breaker)
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{circuit_breaker}
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Will Sargent"]
  s.date = %q{2009-07-13}
  s.description = %q{CircuitBreaker is a relatively simple Ruby mixin that will wrap
 a call to a given service in a circuit breaker pattern.

 The circuit starts off "closed" meaning that all calls will go through.
 However, consecutive failures are recorded and after a threshold is reached,
 the circuit will "trip", setting the circuit into an "open" state.

 In an "open" state, every call to the service will fail by raising
 CircuitBrokenException.

 The circuit will remain in an "open" state until the failure timeout has
 elapsed.

 After the failure_timeout has elapsed, the circuit will go into
 a "half open" state and the call will go through.  A failure will
 immediately pop the circuit open again, and a success will close the
 circuit and reset the failure count.

 require 'circuit_breaker'
 class TestService

   include CircuitBreaker

   def call_remote_service() ...

   circuit_method :call_remote_service

   # Optional
   circuit_handler do |handler|
     handler.logger = Logger.new(STDOUT)
     handler.failure_threshold = 5
     handler.failure_timeout = 5
   end

   # Optional
   circuit_handler_class MyCustomCircuitHandler
 end}
  s.email = ["will.sargent@gmail.com"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.txt"]
  s.files = ["History.txt", "Manifest.txt", "README.txt", "Rakefile", "circuit_breaker.gemspec", "lib/circuit_breaker.rb", "lib/circuit_breaker/circuit_state.rb", "lib/circuit_breaker/circuit_handler.rb", "lib/circuit_breaker/circuit_broken_exception.rb", "spec/unit_spec_helper.rb", "spec/unit/circuit_breaker_spec.rb"]
  s.homepage = %q{http://github.com/wsargent/circuit_breaker}
  s.rdoc_options = ["--main", "README.txt", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{will_sargent}
  s.rubygems_version = %q{1.3.4}
  s.summary = %q{CircuitBreaker is a relatively simple Ruby mixin that will wrap a call to a given service in a circuit breaker pattern}
  s.test_files = ["spec/unit/circuit_breaker_spec.rb", "spec/unit_spec_helper.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rubyist-aasm>, [">= 0"])
      s.add_development_dependency(%q<rspec>, [">= 1.2.7"])
      s.add_development_dependency(%q<hoe>, [">= 2.3.1"])
    else
      s.add_dependency(%q<rubyist-aasm>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 1.2.7"])
      s.add_dependency(%q<hoe>, [">= 2.3.1"])
    end
  else
    s.add_dependency(%q<rubyist-aasm>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 1.2.7"])
    s.add_dependency(%q<hoe>, [">= 2.3.1"])
  end
end
