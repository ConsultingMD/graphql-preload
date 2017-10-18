module GraphQL
  module Preload
    # Preloads ActiveRecord::Associations when called from the Preload::Instrument
    class Loader < GraphQL::Batch::Loader
      attr_reader :association, :conditions, :model

      def cache_key(record)
        record.object_id
      end

      def initialize(model, association, conditions)
        @association = association
        @conditions = conditions
        @model = model

        validate
      end

      def load(record)
        unless record.is_a?(model)
          raise TypeError, "Loader for #{model} can't load associations for #{record.class} objects"
        end

        return Promise.resolve(record) if association_loaded?(record)
        super
      end

      def perform(records)
        preload_association(records)
        records.each { |record| fulfill(record, record) }
      end

      private def association_class
        model.reflect_on_association(association).klass
      end

      private def association_loaded?(record)
        record.association(association).loaded?
      end

      private def preload_association(records)
        if ActiveRecord::VERSION::MAJOR > 3
          ActiveRecord::Associations::Preloader.new.preload(records, association, preload_scope)
        else
          ActiveRecord::Associations::Preloader.new(records, association, conditions: conditions).run
        end
      end

      private def preload_scope
        return unless conditions
        if conditions.respond_to?(:to_proc)
          association_class.send(:instance_eval, &conditions)
        else
          association_class.where(conditions)
        end
      end

      private def validate
        unless association.is_a?(Symbol)
          raise ArgumentError, 'Association must be a Symbol object'
        end

        if conditions && !(conditions.is_a?(Hash) || conditions.respond_to?(:to_proc))
          raise ArgumentError, 'Preload conditions must be a Proc or Hash object'
        end

        unless model < ActiveRecord::Base
          raise ArgumentError, 'Model must be an ActiveRecord::Base descendant'
        end

        return if model.reflect_on_association(association)
        raise TypeError, "Association :#{association} does not exist on #{model}"
      end
    end
  end
end
