# GraphQL::Preload

[![Gem Version](https://badge.fury.io/rb/graphql-preload.svg)](https://rubygems.org/gems/graphql-preload)

Provides a DSL for the [`graphql` gem](https://github.com/rmosolgo/graphql-ruby) that allows ActiveRecord associations to be preloaded in field definitions. Based on a [gist](https://gist.github.com/theorygeek/a1a59a2bf9c59e4b3706ac68d12c8434) by @theorygeek.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'graphql-preload'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install graphql-preload

## Usage

First, enable preloading in your `GraphQL::Schema`:

```ruby
Schema = GraphQL::Schema.define do
  use GraphQL::Batch

  enable_preloading
end
```

Call `preload` when defining your field:

```ruby
PostType = GraphQL::ObjectType.define do
  name 'Post'

  field :comments, !types[!CommentType] do
    # Post.includes(:comments)
    preload :comments

    # Post.includes(:comments, :authors)
    preload [:comments, :authors]

    # Post.includes(:comments, authors: [:followers, :posts])
    preload [:comments, { authors: [:followers, :posts] }]

    resolve ->(obj, args, ctx) { obj.comments }
  end
end
```

### `preload_scope`
Starting with Rails 4.1, you can scope your preloaded records by passing a valid scope to [`ActiveRecord::Associations::Preloader`](https://apidock.com/rails/v4.1.8/ActiveRecord/Associations/Preloader/preload). Scoping can improve performance by reducing the number of models to be instantiated and can help with certain business goals (e.g., only returning records that have not been soft deleted).

This functionality is surfaced through the `preload_scope` option:

```ruby
PostType = GraphQL::ObjectType.define do
  name 'Post'

  field :comments, !types[!CommentType] do
    preload :comments
    preload_scope ->(args, ctx) { Comment.where(deleted_at: nil) }

    # Resolves with records returned from the following query:
    # SELECT "comments".*
    # FROM "comments"
    # WHERE "comments"."deleted_at" IS NULL
    #   AND "comments"."post_id" IN (1, 2, 3)
    resolve ->(obj, args, ctx) { obj.comments }
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ConsultingMD/graphql-preload.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
