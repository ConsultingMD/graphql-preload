require 'test_helper'

class GraphQL::PreloadTest < Minitest::Test
  attr_reader :queries

  def setup
    @queries = []
    QueryNotifier.subscriber = ->(query) { @queries << query }
  end

  def teardown
    QueryNotifier.subscriber = nil
  end

  def test_that_it_has_a_version_number
    refute_nil ::GraphQL::Preload::VERSION
  end

  def test_batched_association_preload
    query_string = <<-GRAPHQL
      {
        products(first: 2) {
          id
          title
          variants {
            id
            title
          }
        }
      }
    GRAPHQL
    result = Schema.execute(query_string)
    expected = {
      "data" => {
        "products" => [
          {
            "id" => "1",
            "title" => "Shirt",
            "variants" => [
              { "id" => "1", "title" => "Red" },
              { "id" => "2", "title" => "Blue" },
            ],
          },
          {
            "id" => "2",
            "title" => "Pants",
            "variants" => [
              { "id" => "4", "title" => "Small" },
              { "id" => "5", "title" => "Medium" },
              { "id" => "6", "title" => "Large" },
            ],
          }
        ]
      }
    }
    assert_equal expected, result
    assert_equal ["Product?limit=2", "Product/1,2/variants"], queries
  end

  def test_batched_association_nested_preload
    query_string = <<-GRAPHQL
      {
        products(first: 2) {
          id
          title
          variantsNestedPreload {
            id
            title
          }
        }
      }
    GRAPHQL
    result = Schema.execute(query_string)
    expected = {
      "data" => {
        "products" => [
          {
            "id" => "1",
            "title" => "Shirt",
            "variantsNestedPreload" => [
              { "id" => "1", "title" => "Red" },
              { "id" => "2", "title" => "Blue" },
            ],
          },
          {
            "id" => "2",
            "title" => "Pants",
            "variantsNestedPreload" => [
              { "id" => "4", "title" => "Small" },
              { "id" => "5", "title" => "Medium" },
              { "id" => "6", "title" => "Large" },
            ],
          }
        ]
      }
    }
    assert_equal expected, result
    assert_equal ["Product?limit=2", "Product/1,2/variants", "ProductVariant/1,2,4,5,6/images"], queries
  end

  def test_query_group_with_sub_queries
    query_string = <<-GRAPHQL
      {
        product(id: "1") {
          variants {
            images { id, filename }
          }
        }
      }
    GRAPHQL
    result = Schema.execute(query_string)
    expected = {
      "data" => {
        "product" => {
          "variants" => [{
            "images" => [
              { "id" => "4", "filename" => "red-shirt.jpg" },
            ]
          }, {
            "images" => [
              { "id" => "5", "filename" => "blue-shirt.jpg" },
            ]
          }]
        }
      }
    }
    assert_equal expected, result
    assert_equal ["Product/1", "Product/1/variants", "ProductVariant/1,2/images"], queries
  end

  def test_loader_reused_after_loading
    query_string = <<-GRAPHQL
      {
        product(id: "2") {
          variants {
            id
            product {
              id
              title
            }
          }
        }
      }
    GRAPHQL
    result = Schema.execute(query_string)
    expected = {
      "data" => {
        "product" => {
          "variants" => [
            { "id" => "4", "product" => { "id" => "2", "title" => "Pants" } },
            { "id" => "5", "product" => { "id" => "2", "title" => "Pants" } },
            { "id" => "6", "product" => { "id" => "2", "title" => "Pants" } },
          ],
        }
      }
    }
    assert_equal expected, result
    assert_equal ["Product/2", "Product/2/variants"], queries
  end
end
