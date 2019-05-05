# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'graphql/preload/version'

Gem::Specification.new do |spec|
  spec.name          = 'graphql-preload'
  spec.version       = GraphQL::Preload::VERSION
  spec.authors       = ['Ryan Foster, Etienne Tripier']
  spec.email         = ['etienne.tripier@grandrounds.com']

  spec.summary       = 'Preload ActiveRecord associations with graphql-batch'
  spec.homepage      = 'https://github.com/ConsultingMD/graphql-preload'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'activerecord', '>= 4.1', '< 6'
  spec.add_runtime_dependency 'graphql', '>= 1.8', '< 2'
  spec.add_runtime_dependency 'graphql-batch', '~> 0.4'
  spec.add_runtime_dependency 'promise.rb', '~> 0.7'

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'pry', '~> 0.10'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'yard', '~> 0.9'
end
