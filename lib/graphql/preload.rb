require 'graphql'
require 'graphql/batch'
require 'promise.rb'

module GraphQL
  # Provides a GraphQL::Field definition to preload ActiveRecord::Associations
  module Preload
    autoload :Instrument, 'graphql/preload/instrument'
    autoload :Loader, 'graphql/preload/loader'
    autoload :VERSION, 'graphql/preload/version'

    module SchemaMethods
      def enable_preloading
        instrument(:field, GraphQL::Preload::Instrument.new)
      end
    end

    module FieldMetadata
      def initialize(*args, preload: nil, preload_scope: nil, **kwargs, &block)
        super(*args, **kwargs, &block)
        self.preload(preload) if preload
        self.preload_scope(preload_scope) if preload_scope
      end

      def preload(associations)
        @preload ||= []
        @preload.concat Array.wrap associations
      end

      def preload_scope(scope_proc)
        @preload_scope = scope_proc
      end

      def to_graphql
        field_defn = super
        field_defn.metadata[:preload] = @preload
        field_defn.metadata[:preload_scope] = @preload_scope
        field_defn
      end
    end
  end

  Schema.extend Preload::SchemaMethods
  Schema::Field.prepend Preload::FieldMetadata
end
