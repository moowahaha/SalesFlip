class CreateDomains < ActiveRecord::Migration
  def self.up
    create_table :domains, :id => false do |t|
      t.integer :pkid, :primary => true
      t.string  :domain
      t.string  :transport
      t.boolean :enabled
    end
  end

  def self.down
    drop_table :domains
  end
end
