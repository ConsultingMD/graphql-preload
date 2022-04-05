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

      private def preload_association(records)
        preloader = ActiveRecord::Associations::Preloader.new.preload(records, association, preload_scope).first
        return unless preload_scope
        return if Gem::Version.new(ActiveRecord::VERSION::STRING) < Gem::Version.new("6.0.0")

        # See https://github.com/rails/rails/issues/36638 for details
        # Solution adapted from https://gist.github.com/palkan/03eb5306a1a3e8addbe8df97a298a466
        if preloader.is_a?(::ActiveRecord::Associations::Preloader::AlreadyLoaded)
          raise ArgumentError,
              "Preloading association twice is not possible. " \
              "To resolve this add `preload #{association.inspect}` to the GraphQL field definition."
        end

        # this commit changes the way preloader works with scopes
        # https://github.com/rails/rails/commit/2847653869ffc1ff5139c46e520c72e26618c199#diff-3bba5f66eb1ed62bd5700872fcd6c632
        preloader.send(:owners).each do |owner|
          preloader.send(:associate_records_to_owner, owner, preloader.records_by_owner[owner] || [])
        end
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
