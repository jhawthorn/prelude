require 'fileutils'
require 'active_record'
require 'pry'
require_relative '../lib/prelude'

# Remove existing
FileUtils.rm_rf('db.sqlite3')

# Connect
ActiveRecord::Base.establish_connection(
  adapter:  "sqlite3",
  host:     "localhost",
  database: "db.sqlite3"
)

# Create the appropriate structure
ActiveRecord::Migration.verbose = false
ActiveRecord::Schema.define do
  create_table :breweries do |table|
    table.column :name, :string
  end
end
