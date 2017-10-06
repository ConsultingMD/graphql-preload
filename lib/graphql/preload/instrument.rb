module GraphQL
  module Preload
    # Provides an instrument for the GraphQL::Field :preload definition
    class Instrument
      def instrument(_type, field)
        return field unless field.metadata.include?(:preload)

        old_resolver = field.resolve_proc
        new_resolver = ->(obj, args, ctx) do
          return old_resolver.call(obj, args, ctx) unless obj

          if field.metadata[:preload_scope]
            scope_lambda = field.metadata[:preload_scope]
            scope = scope_lambda.call(args, ctx)
          end

          preload(obj, field.metadata[:preload], scope_lambda, scope).then do
            old_resolver.call(obj, args, ctx)
          end
        end

        field.redefine do
          resolve(new_resolver)
        end
      end

      private def preload(record, associations, scope_lambda, scope)
        if associations.is_a?(String)
          raise TypeError, "Expected #{associations} to be a Symbol, not a String"
        elsif associations.is_a?(Symbol)
          return preload_single_association(record, associations, scope_lambda, scope)
        end

        promises = []

        Array.wrap(associations).each do |association|
          case association
          when Symbol
            promises << preload_single_association(record, association, scope_lambda, scope)
          when Array
            association.each do |sub_association|
              promises << preload(record, sub_association, scope_lambda, scope)
            end
          when Hash
            association.each do |sub_association, nested_association|
              promises << preload_single_association(record, sub_association,
                scope_lambda, scope).then do
                associated_records = record.public_send(sub_association)

                case associated_records
                when ActiveRecord::Base
                  preload(associated_records, nested_association, scope_lambda, scope)
                else
                  Promise.all(
                    Array.wrap(associated_records).map do |associated_record|
                      preload(associated_record, nested_association, scope_lambda, scope)
                    end
                  )
                end
              end
            end
          end
        end

        Promise.all(promises)
      end

      private def preload_single_association(record, association, scope_lambda, scope)
        loader = GraphQL::Preload::Loader.for(record.class, association, scope_lambda)
        loader.scope = scope
        loader.load(record)
      end
    end
  end
end
