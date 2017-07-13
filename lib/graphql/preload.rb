require 'graphql'
require 'promise.rb'

GraphQL::Field.accepts_definitions(
  preload: ->(type, *args) do
    type.metadata[:preload] ||= []
    type.metadata[:preload].concat(args)
  end
)

module GraphQL
  # Provides a GraphQL::Field definition to preload ActiveRecord::Associations
  module Preload
    autoload :Instrument, 'graphql/preload/instrument'
    autoload :Loader, 'graphql/preload/loader'
    autoload :VERSION, 'graphql/preload/version'
  end
end
