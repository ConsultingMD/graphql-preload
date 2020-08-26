class ImageType < GraphQL::Schema::Object
  field :id, ID, null: false
  field :filename, String, null: false
end

class ProductVariantType < GraphQL::Schema::Object
  field :id, ID, null: false
  field :title, String, null: false
  field :images, [ImageType], null: true do
    extension GraphQL::Preload::FieldExtension, :images
  end
  field :product, GraphQL::Schema::LateBoundType.new('Product'), null: false
end

class ProductType < GraphQL::Schema::Object
  field :id, ID, null: false
  field :title, String, null: false
  field :image, ImageType, null: true, preload: :image
  field :variants, [ProductVariantType], null: true do
    extension GraphQL::Preload::FieldExtension, :variants
  end
  field :variants_nested_preload, [ProductVariantType], null: true do
    extension GraphQL::Preload::FieldExtension, variants: :images
  end
  def variants_nested_preload
    object.variants
  end
end

class QueryType < GraphQL::Schema::Object
  graphql_name 'query'

  field :product, ProductType, null: true do
    argument :id, ID, required: true
  end

  def product(id:)
    Product.find(id)
  end

  field :products, [ProductType], null: true do
    argument :first, Int, required: true
  end

  def products(first:)
    Product.first(first)
  end
end

class Schema < GraphQL::Schema
  query QueryType

  if ENV['TESTING_INTERPRETER'] == 'true'
    use GraphQL::Execution::Interpreter
    # This probably has no effect, but just to get the full test:
    use GraphQL::Analysis::AST
  end

  use GraphQL::Batch
  enable_preloading
end
