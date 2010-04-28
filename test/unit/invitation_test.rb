require 'test_helper'

class InvitationTest < ActiveSupport::TestCase
  context 'Class' do
    should_have_key :email, :inviter_id, :invited_id, :created_at, :updated_at, :user_type,
      :code
    should_require_key :email, :inviter
    should_have_constant :user_types
    should_belong_to :inviter, :invited
  end

  context 'Named scopes' do
    context 'by_company' do
      setup do
        @user = User.make(:annika)
        @user2 = User.make
        @user3 = User.make(:company => @user.company)
        @invitation = Invitation.make(:inviter => @user)
        @invitation2 = Invitation.make(:inviter => @user2)
        @invitation3 = Invitation.make(:inviter => @user3)
      end

      should 'return all invitations created by a user belonging to the supplied company' do
        result = Invitation.by_company(@user.company)
        assert_equal 2, result.count
        assert result.include?(@invitation)
        assert result.include?(@invitation3)
      end
    end
  end

  context 'Instance' do
    setup do
      @invitation = Invitation.make_unsaved
    end

    should 'generate code on creation' do
      @invitation.code = nil
      @invitation.save!
      assert @invitation.code
    end

    should 'send invitation email after creation' do
      ActionMailer::Base.deliveries.clear
      @invitation.save!
      assert_equal 1, ActionMailer::Base.deliveries.length
    end
  end
end
