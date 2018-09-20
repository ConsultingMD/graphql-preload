# frozen_string_literal: true
require "active_record"
require "sqlite3"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

ActiveRecord::Schema.define(version: 0) do
  create_table :users do |t|
    t.string :name
  end

  create_table :posts do |t|
    t.string     :title
    t.text       :text
    t.float      :rating
    t.references :author, foreign_key: { to_table: :users, column: :author_id, on_delete: :cascade }
  end

  create_table :comments do |t|
    t.text       :text
    t.references :post,   foreign_key: { on_delete: :cascade }
    t.references :author, foreign_key: { to_table: :users, column: :author_id, on_delete: :cascade }
  end
end

class User < ActiveRecord::Base
  has_many :posts,    inverse_of: :author, foreign_key: :author_id
  has_many :comments, inverse_of: :author, foreign_key: :author_id
end

class Post < ActiveRecord::Base
  belongs_to :author, class_name: "User"
  has_many :comments
end

class Comment < ActiveRecord::Base
  belongs_to :author, class_name: "User"
  belongs_to :post
end

alice, bob = User.create!([{ name: 'Alice' }, { name: 'Bob' }])

alice.posts.create!([{ title: "Foo", rating: 4 }, { title: "Bar", rating: 8 }])
bob.posts.create!([{ title: "Baz", rating: 7 }, { title: "Huh", rating: 4.2 }])

Post.all.each do |post|
  alice.comments.create(post: post, text: "Great post!")
  bob.comments.create(post: post, text: "Great post!")
end
