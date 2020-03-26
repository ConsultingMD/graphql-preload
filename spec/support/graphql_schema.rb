# frozen_string_literal: true

class CommentType < GraphQL::Schema::Object
  field :id,        ID,     null: false
  field :text,      String, null: false
  field :author_id, ID,     null: false
  field :post_id,   ID,     null: false
end

class PostType < GraphQL::Schema::Object
  field :id,        ID,            null: false
  field :title,     String,        null: false
  field :text,      String,        null: false
  field :rating,    Float,         null: false
  field :comments,  [CommentType], null: false, preload: :comments
  field :author_id, ID,            null: false
end

class UserType < GraphQL::Schema::Object
  field :id,       ID,            null: false
  field :name,    String,         null: false
  field :comments, [CommentType], null: false, preload: :comments
  field :posts,    [PostType],    null: false,
                                  preload: :posts,
                                  preload_scope: ->(*) { Post.order(rating: :desc) }
end

class QueryType < GraphQL::Schema::Object
  field :users, [UserType], null: false
  field :posts, [PostType], null: false

  def users
    User.all
  end

  def posts
    Post.all
  end
end

class PreloadSchema < GraphQL::Schema
  use GraphQL::Batch
  enable_preloading

  if TESTING_GRAPHQL_RUBY_INTERPRETER
    use GraphQL::Execution::Interpreter
    use GraphQL::Analysis::AST
  end

  query QueryType
end
