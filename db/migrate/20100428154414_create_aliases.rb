class CreateAliases < ActiveRecord::Migration
  def self.up
    create_table :aliases, :id => false do |t|
      t.integer :pkid, :primary => true
      t.string  :mail
      t.string  :destination
      t.boolean :enabled
    end
  end

  def self.down
    drop_table :aliases
  end
end
