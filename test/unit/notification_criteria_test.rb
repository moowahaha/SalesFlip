require 'test_helper'

class NotificationCriteriaTest < ActiveSupport::TestCase
  context 'Class' do
    should_have_key :model, :criteria, :frequency, :send_at
    should_require_key :model, :frequency
    should_have_constant :frequencies
    should_belong_to :user
  end

  context 'Instance' do
    setup do
      @notification_criteria = NotificationCriteria.new
    end

    should 'be able to dynamically add criteria' do
      @notification_criteria.criteria_source_in = 0
      assert_equal({ 'source' => { '$in' => 0 } }, @notification_criteria.criteria)
    end

    should 'be able to dynamically retrieve criteria' do
      @notification_criteria.criteria = { 'source' => { '$in' => 0 } }
      assert_equal 0, @notification_criteria.criteria_source_in
    end
  end
end
