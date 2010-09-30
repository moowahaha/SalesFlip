# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100428154703) do

  create_table "aliases", :id => false, :force => true do |t|
    t.integer "pkid"
    t.string  "mail"
    t.string  "destination"
    t.boolean "enabled"
  end

  create_table "domains", :id => false, :force => true do |t|
    t.integer "pkid"
    t.string  "domain"
    t.string  "transport"
    t.boolean "enabled"
  end

end
