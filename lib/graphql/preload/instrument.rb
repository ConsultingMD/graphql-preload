module GraphQL
  module Preload
    # Provides an instrument for the GraphQL::Field :preload definition
    class Instrument
      def instrument(_type, field)
        return field unless field.metadata.include?(:preload)

        old_resolver = field.resolve_proc
        new_resolver = ->(obj, args, ctx) do
          return old_resolver.call(obj, args, ctx) unless obj

          preload(obj, field.metadata[:preload]).then do
            old_resolver.call(obj, args, ctx)
          end
        end

        field.redefine do
          resolve(new_resolver)
        end
      end

      private def preload(record, associations)
        raise TypeError, "Expected #{associations} to be a Symbol, not a String" if associations.is_a?(String)
        return preload_single_association(record, associations) if associations.is_a?(Symbol)

        promises = []

        Array.wrap(associations).each do |association|
          case association
          when Symbol
            promises << preload_single_association(record, association)
          when Array
            association.each do |sub_association|
              promises << preload(record, sub_association)
            end
          when Hash
            association.each do |sub_association, nested_association|
              promises << preload_single_association(record, sub_association).then do
                associated_records = record.public_send(sub_association)

                case associated_records
                when ActiveRecord::Base
                  preload(associated_records, nested_association)
                else
                  Promise.all(
                    Array.wrap(associated_records).map do |associated_record|
                      preload(associated_record, nested_association)
                    end
                  )
                end
              end
            end
          end
        end

        Promise.all(promises)
      end

      private def preload_single_association(record, association)
        GraphQL::Preload::Loader.for(record.class, association).load(record)
      end
    end
  end
end
