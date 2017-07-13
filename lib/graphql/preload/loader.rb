module GraphQL
  module Preload
    # Preloads ActiveRecord::Associations when called from the Preload::Instrument
    class Loader < GraphQL::Batch::Loader
      attr_reader :association, :model

      def initialize(model, association)
        @association = association
        @model = model

        validate_association
      end

      def load(record)
        unless record.is_a?(model)
          raise TypeError, "loader for #{model.name} can't load associations for #{record.class.name} objects"
        end

        if record.association(association).loaded?
          Promise.resolve(record)
        else
          super
        end
      end

      def perform(records)
        if ActiveRecord::VERSION::MAJOR > 3
          ActiveRecord::Associations::Preloader.new.preload(records, association)
        else
          ActiveRecord::Associations::Preloader.new(records, association).run
        end

        records.each { |record| fulfill(record, record) }
      end

      private def validate_association
        unless association.is_a?(Symbol)
          raise ArgumentError, 'association must be a Symbol object'
        end

        unless model < ActiveRecord::Base
          raise ArgumentError, 'model must be an ActiveRecord::Base descendant'
        end

        return if model.reflect_on_association(association)

        raise TypeError, "association :#{association} does not exist on #{model.name}"
      end
    end
  end
end
