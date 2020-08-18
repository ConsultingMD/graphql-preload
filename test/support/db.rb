class QueryNotifier
  class << self
    attr_accessor :subscriber

    def call(query)
      subscriber&.call(query)
    end
  end
end

class Base < ActiveRecord::Base
  self.abstract_class = true

  def self.first(count)
    QueryNotifier.call("#{name}?limit=#{count}")
    super
  end

  def self.find(ids)
    QueryNotifier.call("#{name}/#{Array(ids).join(',')}")
    super
  end

  def self.preload_association(owners, association)
    QueryNotifier.call("#{name}/#{owners.map(&:id).join(',')}/#{association}")
    super
  end
end
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: './_test_.db')

ActiveRecord::Schema.define do
  self.verbose = false
  create_table :images, force: true do |t|
    t.column :owner_id, :integer
    t.column :owner_type, :string
    t.column :filename, :string
  end

  create_table :products, force: true do |t|
    t.column :title, :string
    t.column :image_id, :integer
  end

  create_table :product_variants, force: true do |t|
    t.column :title, :string
    t.column :product_id, :integer
  end
end

class Image < Base; end

class ProductVariant < Base
  belongs_to :product
  has_many :images,  -> { where(owner_type: 'ProductVariant') }, foreign_key: :owner_id
end

class Product < Base
  has_many :images,  -> { where(owner_type: 'Product') }, foreign_key: :owner_id
  has_many :variants, class_name: 'ProductVariant'
end

Product.create(id: 1, title: 'Shirt', image_id: 1)
Product.create(id: 2, title: 'Pants', image_id: 2)
Product.create(id: 3, title: 'Sweater', image_id: 3)

ProductVariant.create(id: 1, product_id: 1, title: 'Red')
ProductVariant.create(id: 2, product_id: 1, title: 'Blue')
ProductVariant.create(id: 4, product_id: 2, title: 'Small')
ProductVariant.create(id: 5, product_id: 2, title: 'Medium')
ProductVariant.create(id: 6, product_id: 2, title: 'Large')
ProductVariant.create(id: 7, product_id: 3, title: 'Default')

Image.create(id: 1, owner_type: 'Product', owner_id: 1, filename: 'shirt.jpg')
Image.create(id: 2, owner_type: 'Product', owner_id: 2, filename: 'pants.jpg')
Image.create(id: 3, owner_type: 'Product', owner_id: 3, filename: 'sweater.jpg')
Image.create(id: 4, owner_type: 'ProductVariant', owner_id: 1, filename: 'red-shirt.jpg')
Image.create(id: 5, owner_type: 'ProductVariant', owner_id: 2, filename: 'blue-shirt.jpg')
Image.create(id: 6, owner_type: 'ProductVariant', owner_id: 3, filename: 'small-pants.jpg')

module LoaderExtensions
  private

  def preload_association(records)
    QueryNotifier.call("#{model.name}/#{records.map(&:id).join(',')}/#{association}")
    super
  end
end

GraphQL::Preload::Loader.prepend(LoaderExtensions)
