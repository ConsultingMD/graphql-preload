module GraphQL
  module Preload
    # Provides an instrument for the GraphQL::Field :preload definition
    class Instrument
      def instrument(_type, field)
        return field unless field.metadata.include?(:preload)

        old_resolver = field.resolve_proc
        new_resolver = ->(obj, args, ctx) do
          return old_resolver.call(obj, args, ctx) unless obj

          associations, conditions = field.metadata.values_at(:preload, :preload_conditions)

          preload(obj, associations, conditions).then do
            old_resolver.call(obj, args, ctx)
          end
        end

        field.redefine do
          resolve(new_resolver)
        end
      end

      private def preload(record, associations, conditions)
        raise TypeError, "Expected #{associations} to be a Symbol, not a String" if associations.is_a?(String)
        return preload_single_association(record, associations, conditions) if associations.is_a?(Symbol)

        promises = []

        Array.wrap(associations).each do |association|
          case association
          when Symbol
            promises << preload_single_association(record, association, conditions)
          when Array
            association.each do |sub_association|
              promises << preload(record, sub_association, conditions)
            end
          when Hash
            association.each do |sub_association, nested_association|
              promises << preload_single_association(record, sub_association, conditions).then do
                associated_records = record.public_send(sub_association)

                case associated_records
                when ActiveRecord::Base
                  preload(associated_records, nested_association, conditions)
                else
                  Promise.all(
                    Array.wrap(associated_records).map do |associated_record|
                      preload(associated_record, nested_association, conditions)
                    end
                  )
                end
              end
            end
          end
        end

        Promise.all(promises)
      end

      private def preload_single_association(record, association, conditions)
        GraphQL::Preload::Loader.for(record.class, association, conditions).load(record)
      end
    end
  end
end
