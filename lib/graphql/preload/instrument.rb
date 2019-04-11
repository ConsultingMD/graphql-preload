module GraphQL
  module Preload
    # Provides an instrument for the GraphQL::Field :preload definition
    class Instrument
      def instrument(_type, field)
        metadata = merged_metadata(field)
        return field if metadata.fetch(:preload, nil).nil?

        old_resolver = field.resolve_proc
        new_resolver = ->(obj, args, ctx) do
          return old_resolver.call(obj, args, ctx) unless obj

          if metadata[:preload_scope]
            scope = metadata[:preload_scope].call(args, ctx)
          end

          is_graphql_object = obj.is_a?(GraphQL::Schema::Object)
          respond_to_object = obj.respond_to?(:object)
          record = is_graphql_object && respond_to_object ? obj.object : obj

          preload(record, metadata[:preload], scope).then do
            old_resolver.call(obj, args, ctx)
          end
        end

        field.redefine do
          resolve(new_resolver)
        end
      end

      private def preload(record, associations, scope)
        if associations.is_a?(String)
          raise TypeError, "Expected #{associations} to be a Symbol, not a String"
        elsif associations.is_a?(Symbol)
          return preload_single_association(record, associations, scope)
        end

        promises = []

        Array.wrap(associations).each do |association|
          case association
          when Symbol
            promises << preload_single_association(record, association, scope)
          when Array
            association.each do |sub_association|
              promises << preload(record, sub_association, scope)
            end
          when Hash
            association.each do |sub_association, nested_association|
              promises << preload_single_association(record, sub_association, scope).then do
                associated_records = record.public_send(sub_association)

                case associated_records
                when ActiveRecord::Base
                  preload(associated_records, nested_association, scope)
                else
                  Promise.all(
                    Array.wrap(associated_records).map do |associated_record|
                      preload(associated_record, nested_association, scope)
                    end
                  )
                end
              end
            end
          end
        end

        Promise.all(promises)
      end

      private def preload_single_association(record, association, scope)
        # We would like to pass the `scope` (which is an `ActiveRecord::Relation`),
        # directly into `Loader.for`. However, because the scope is
        # created for each parent record, they are different objects and
        # return different loaders, breaking batching.
        # Therefore, we pass in `scope.to_sql`, which is the same for all the
        # scopes and set the `scope` using an accessor. The actual scope
        # object used will be the last one, which shouldn't make any difference,
        # because even though they are different objects, they are all
        # functionally equivalent.
        loader = GraphQL::Preload::Loader.for(record.class, association, scope.try(:to_sql))
        loader.scope = scope
        loader.load(record)
      end

      private def merged_metadata(field)
        type_class = field.metadata.fetch(:type_class, nil)

        if type_class.nil? || !type_class.respond_to?(:to_graphql)
          field.metadata
        else
          field.metadata.merge(type_class.to_graphql.metadata)
        end
      end

    end
  end
end
