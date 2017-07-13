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

      private def preload(model, associations)
        return preload_single_association(model, associations) if associations.is_a?(Symbol)

        promises = []

        Array.wrap(associations).each do |association|
          case association
          when Symbol
            promises << preload_single_association(model, association)
          when Array
            association.each { |sub_association| promises << preload(model, sub_association) }
          when Hash
            association.each do |association_key, sub_association|
              promises << preload_single_association(model, association_key).then do
                associated_model = model.public_send(association_key)

                case associated_model
                when ActiveRecord::Base
                  preload(associated_model, sub_association)
                else
                  Promise.all(
                    Array.wrap(associated_model).map do |next_model|
                      preload(next_model, sub_association)
                    end
                  )
                end
              end
            end
          end
        end

        Promise.all(promises)
      end

      private def preload_single_association(model, association)
        return Promise.resolve(model) if model.association(association).loaded?
        GraphQL::Preload::Loader.for(model.class, association).load(model)
      end
    end
  end
end
