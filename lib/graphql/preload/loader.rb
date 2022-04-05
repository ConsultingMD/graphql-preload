# frozen_string_literal: true

module GraphQL
  module Preload
    # Preloads ActiveRecord::Associations when called from the Preload::Instrument
    class Loader < GraphQL::Batch::Loader
      attr_accessor :scope
      attr_reader :association, :model

      def cache_key(record)
        record.object_id
      end

      def initialize(model, association, _scope_sql)
        @association = association
        @model = model

        validate_association
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

      private

      def association_loaded?(record)
        record.association(association).loaded?
      end

      def preload_association(records)
        ActiveRecord::Associations::Preloader.new(records: records, associations: association, scope: preload_scope)
      end

      def preload_scope
        return nil unless scope

        reflection = model.reflect_on_association(association)
        raise ArgumentError, 'Cannot specify preload_scope for polymorphic associations' if reflection.polymorphic?

        scope if scope.try(:klass) == reflection.klass
      end

      def validate_association
        raise ArgumentError, 'Association must be a Symbol object' unless association.is_a?(Symbol)
        raise ArgumentError, "Model #{model} must be an ActiveRecord::Base descendant" unless model < ActiveRecord::Base

        return if model.reflect_on_association(association)

        raise TypeError, "Association :#{association} does not exist on #{model}"
      end
    end
  end
end
