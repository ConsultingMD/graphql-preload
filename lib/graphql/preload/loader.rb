module GraphQL
  module Preload
    class Loader < GraphQL::Batch::Loader
      attr_reader :association, :klass

      def initialize(klass, association)
        @association = association
        @klass = klass

        validate_association

        freeze
      end

      def load(model)
        raise TypeError,
          "loader for #{klass.name} can't load associations for #{model.class.name} objects" unless model.is_a?(klass)

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
        raise ArgumentError,
          "association must be a Symbol object" unless association.is_a?(Symbol)
        raise ArgumentError,
          "class must be an ActiveRecord::Base descendant" unless klass < ActiveRecord::Base
        raise TypeError,
          "association :#{association} does not exist on #{klass.name}" unless klass.reflect_on_association(association)
      end
    end
  end
end
