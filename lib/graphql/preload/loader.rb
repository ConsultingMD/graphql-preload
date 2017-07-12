module GraphQL
  module Preload
    # Preloads ActiveRecord::Associations when called from the Preload::Instrument
    class Loader < GraphQL::Batch::Loader
      attr_reader :association, :klass

      def initialize(klass, association)
        @association = association
        @klass = klass

        validate_association

        freeze
      end

      def load(model)
        unless model.is_a?(klass)
          raise TypeError, "loader for #{klass.name} can't load associations for #{model.class.name} objects"
        end

        if model.association(association).loaded?
          Promise.resolve(model)
        else
          super
        end
      end

      def perform(models)
        ActiveRecord::Associations::Preloader.new.preload(models, association)
        models.each { |model| fulfill(model, model) }
      end

      private def validate_association
        unless association.is_a?(Symbol)
          raise ArgumentError, 'association must be a Symbol object'
        end

        unless klass < ActiveRecord::Base
          raise ArgumentError, 'class must be an ActiveRecord::Base descendant'
        end

        return if klass.reflect_on_association(association)

        raise TypeError, "association :#{association} does not exist on #{klass.name}"
      end
    end
  end
end
