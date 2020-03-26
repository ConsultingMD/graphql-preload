# frozen_string_literal: true
require "spec_helper"

RSpec.describe GraphQL::Preload do
  subject do
    @result ||=
      schema.execute(query: query_string, context: {}, variables: {})
  end

  shared_examples "test suite" do
    context "without associations" do
      let(:query_string) { "query { products { title } }" }

      it "doesn't load associations at all" do
        expect { subject }.not_to exceed_query_limit 1
      end
    end

    context "with associations" do
      let(:query_string) do
        <<~QRAPHQL
        query { posts { title comments { text } } }
        QRAPHQL
      end

      it "preloads associations by single query" do
        expect { subject }.to exceed_query_limit 1 # to ensure that GraphQL query at least works
        expect { subject }.not_to exceed_query_limit 2
        posts = subject.dig("data", "posts")
        expect(posts.size).to eq(4)
        expect(posts.flat_map { |p| p["comments"] }.size).to eq(8)
      end
    end

    context "with associations with custom scopes" do
      let(:query_string) do
        <<~QRAPHQL
        query { users { name posts { title } } }
        QRAPHQL
      end

      it "preloads associations by single query and given order" do
        expect { subject }.not_to exceed_query_limit 2
        posts = subject.dig("data", "users").flat_map { |p| p["posts"] }
        # Posts for every user should be from greater rating to lower
        expect(posts.map { |p| p["title"] }).to eq(%w[Bar Foo Baz Huh])
      end
    end
  end

  context "modern class-based GraphQL schema" do
    let(:schema) { PreloadSchema }

    include_examples "test suite"
  end

  context "legacy define-based GraphQL schema" do
    next if TESTING_GRAPHQL_RUBY_INTERPRETER # No interpreter runtime these days

    let(:schema) { Legacy::PreloadSchema }

    include_examples "test suite"
  end
end
