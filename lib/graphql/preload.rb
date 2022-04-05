# frozen_string_literal: true

require 'graphql'
require 'graphql/batch'
require 'promise.rb'

module GraphQL
  # Provides a GraphQL::Field definition to preload ActiveRecord::Associations
  module Preload
    autoload :Instrument, 'graphql/preload/instrument'
    autoload :FieldExtension, 'graphql/preload/field_extension'
    autoload :Loader, 'graphql/preload/loader'
    autoload :VERSION, 'graphql/preload/version'

    module SchemaMethods
      def enable_preloading
        instrument(:field, GraphQL::Preload::Instrument.new)
      end
    end

    module FieldMetadata
      attr_reader :preload
      attr_reader :preload_scope

      def initialize(*args, preload: nil, preload_scope: nil, **kwargs, &block)
        if preload
          @preload ||= []
          @preload.concat Array.wrap preload
        end

        @preload_scope = preload_scope if preload_scope

        super(*args, **kwargs, &block)
      end

      def to_graphql
        field_defn = super
        field_defn.metadata[:preload] = @preload if defined?(@preload) && @preload
        field_defn.metadata[:preload_scope] = @preload_scope if defined?(@preload_scope) && @preload_scope
        field_defn
      end
    end
  end

  Schema.extend Preload::SchemaMethods
  Schema::Field.prepend Preload::FieldMetadata
end
