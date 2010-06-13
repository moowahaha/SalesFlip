require 'test_helper.rb'

class CompanyTest < ActiveSupport::TestCase
  context 'Class' do
    should_have_key :name
    should_require_key :name
    should_have_many :users
  end

  context 'Instance' do

    should 'validate uniqueness of name' do
      Company.make(:jobboersen)
      @company = Company.make_unsaved(:jobboersen)
      assert !@company.valid?
      assert @company.errors[:name]
    end
  end
end
