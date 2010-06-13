require 'test_helper.rb'

class SearchTest < ActiveSupport::TestCase
  context 'Class' do
    should_have_key :terms, :user_id, :created_at, :updated_at, :collections, :company
    should_belong_to :user
  end

  context 'Instance' do
    setup do
      @search = Search.make_unsaved
    end

    should 'require terms if no company text' do
      @search.terms = nil
      @search.company = nil
      assert !@search.valid?
      assert @search.errors[:terms]
      @search.company = 'asfefa'
      assert @search.valid?
    end

    should 'require company if no terms set' do
      @search.terms = nil
      @search.company = nil
      assert !@search.valid?
      assert @search.errors[:company]
      @search.terms = 'asfef'
      assert @search.valid?
    end
  end
end
