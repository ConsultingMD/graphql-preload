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
            scope = field.metadata[:preload_scope].call(args, ctx)
          end

          preload(obj.object, field.metadata[:preload], scope).then do
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
              promises << preload_single_association(record, sub_association,
                  scope).then do
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
        # We would like to pass the `scope` (which is an
        # `ActiveRecord::Relation`), directly into `Loader.for`, because that is
        # what is needed for `Preloader.new`.  However, because the scope is
        # created for each parent record, they are different objects and
        # therefore would return different loaders, breaking batching.
        # Therefore, we pass in `scope.to_sql`, which is the same for all the
        # scopes and set the `scope` using an accessor.  So the actual scope
        # object used will be the last one, which shouldn't make any difference,
        # beacuse even though they are different objects, they are all
        # equivalent.

        loader = GraphQL::Preload::Loader.for(record.class, association,
          scope.try(:to_sql))
        loader.scope = scope
        loader.load(record)
      end
    end
  end
end
