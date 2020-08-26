$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require "pry-byebug"
require "active_record"
require 'graphql/preload'

require_relative 'support/db'
require_relative 'support/schema'

require 'minitest/autorun'
