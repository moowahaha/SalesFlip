require File.dirname(__FILE__) + '/../../test_helper'
require 'action_view/test_case'
require 'action_view/helpers'
require 'open-uri'

class ApplicationHelperTest < ActionView::TestCase

  include ApplicationHelper

  should "link to create a new model" do
    assert_equal add_new('Add Lead','/leads/new'), "<a href='/leads/new' id='new'><b>+</b>Add Lead</a>"
  end

  context "show_attribute" do
    setup do
      @lead = Lead.make
    end

    should "display I18n label and a model's attribute if it is present" do
      assert_equal show_attribute(@lead,'first_name'), '<dt>First Name</dt><dd>Fern</dd>'
    end

    should "display I18n label and custom text if a model's attribute is present" do
      assert_equal show_attribute(@lead,'first_name',"<b>#{@lead.first_name}</b>"), '<dt>First Name</dt><dd><b>Fern</b></dd>'
    end

    should 'use to_s if attribute is not a string' do
      assert_equal show_attribute(@lead, 'identifier'), "<dt>Identifier</dt><dd>#{@lead.identifier}</dd>"
    end
  end

  context "rating_for" do
    should "show rating in darkened unicode stars if rating is present" do
      @lead = Lead.make(:rating => 1)
      assert_equal rating_for(@lead), "<span class='rating'><span class='on'>&#9733;</span><span class='off'>&#9733;</span><span class='off'>&#9733;</span><span class='off'>&#9733;</span><span class='off'>&#9733;</span></span>"
    end

    should "show grayed out unicode stars if rating is not present" do
      @lead= Lead.make
      assert_equal rating_for(@lead), "<span class='rating'><span class='off'>&#9733;</span><span class='off'>&#9733;</span><span class='off'>&#9733;</span><span class='off'>&#9733;</span><span class='off'>&#9733;</span></span>"
    end
  end

  context "activity_icon" do
    should "show appropriate unicode icon for a user's action" do
      assert_equal activity_icon('created')    , "&#9998;"
      assert_equal activity_icon('updated')    , "&#9998;"
      assert_equal activity_icon('re-assigned'), "&#10132;"
      assert_equal activity_icon('rejected')   , "&#10008;"
      assert_equal activity_icon('converted')  , "&#10004;"
      assert_equal activity_icon('deleted')    , "&#10006;"
      assert_equal activity_icon('whatever')   , "&#9670;"
    end
  end
end
