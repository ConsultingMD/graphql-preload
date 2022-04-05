# frozen_string_literal: true

require 'graphql/preload/field_preloader'

module GraphQL
  module Preload
    class Instrument
      include FieldPreloader

      def instrument(_type, field)
        return field unless field.metadata.include?(:preload)

        if defined?(FieldExtension) && (type_class = field.metadata[:type_class])
          type_class.extension(FieldExtension)
          field
        else
          old_resolver = field.resolve_proc
          new_resolver = lambda do |obj, args, ctx|
            return old_resolver.call(obj, args, ctx) unless obj

            scope = field.metadata[:preload_scope].call(args, ctx) if field.metadata[:preload_scope]

            preload(obj.object, field.metadata[:preload], scope).then do
              old_resolver.call(obj, args, ctx)
            end
          end

          field.redefine do
            resolve(new_resolver)
          end
        end
      end
    end
  end
end
