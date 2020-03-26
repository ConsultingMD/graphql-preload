# frozen_string_literal: true

module Legacy
  CommentType = GraphQL::ObjectType.define do
    name 'Comment'

    field :id, !types.ID
    field :text, !types.String
    field :author_id, !types.ID
    field :post_id, !types.ID
  end

  PostType = GraphQL::ObjectType.define do
    name 'Post'

    field :id, !types.ID
    field :title, !types.String
    field :text, !types.String
    field :rating, !types.String
    field :author_id, !types.ID
    field :comments, !types[!CommentType] do
      # Post.includes(:comments)
      preload :comments

      resolve ->(obj, _args, _ctx) { obj.comments }
    end
  end


  UserType = GraphQL::ObjectType.define do
    name 'User'

    field :id, !types.ID
    field :name, !types.String
    field :comments, !types[!CommentType] do
      preload :comments

      resolve ->(obj, _args, _ctx) { obj.comments }
    end

    field :posts, !types[!PostType] do
      preload :posts
      preload_scope ->(*) { Post.order(rating: :desc) }

      resolve ->(obj, _args, _ctx) { obj.posts }
    end
  end

  QueryType = GraphQL::ObjectType.define do
    name 'Query'

    field :users do
      type !types[!UserType]
      resolve ->(*) { User.all }
    end

    field :posts do
      type !types[!PostType]
      resolve ->(*) { Post.all }
    end
  end

  PreloadSchema = GraphQL::Schema.define do
    use GraphQL::Batch

    enable_preloading

    query QueryType
  end
end