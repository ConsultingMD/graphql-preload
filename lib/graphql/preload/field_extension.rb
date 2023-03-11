# frozen_string_literal: true

require 'graphql/preload/field_preloader'

module GraphQL
  module Preload
    class FieldExtension < GraphQL::Schema::FieldExtension
      include FieldPreloader

      def resolve(object:, arguments:, context:)
        yield(object, arguments) unless object

        scope = options[:preload_scope].call(arguments, context) if options[:preload_scope]

        record = object.is_a?(GraphQL::Schema::Object) && object.respond_to?(:object) ? object.object : object

        preload(record, options[:preload], scope).then do
          yield(object, arguments)
        end
      end
    end
  end
end
