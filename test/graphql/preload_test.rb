require 'test_helper'

module GraphQL
  class PreloadTest < Minitest::Test
    def test_that_it_has_a_version_number
      refute_nil ::GraphQL::Preload::VERSION
    end
  end
end
