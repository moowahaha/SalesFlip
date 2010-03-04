require 'test_helper.rb'

class ContactTest < ActiveSupport::TestCase
  context "Class" do
    should_have_constant :accesses, :titles, :permissions
    should_act_as_paranoid
    should_be_trackable

    context 'create_for' do
      setup do
        @account = Account.make(:careermee)
        @lead = Lead.make(:call_erich, :user => @account.user)
      end

      should 'create a contact from the supplied lead and account' do
        Contact.create_for(@lead, @account)
        assert_equal 1, Contact.count
        assert Contact.find_by_first_name_and_last_name(@lead.first_name, @lead.last_name)
        assert_equal 1, @account.contacts.count
      end

      should 'assign lead to contact' do
        contact = Contact.create_for(@lead, @account)
        assert_equal @lead, contact.lead
      end

      should 'not create the contact if the supplied account is invalid' do
        @account.name = nil
        contact = Contact.create_for(@lead, @account)
        assert_equal 0, Contact.count
      end
    end
  end

  context "Instance" do
    setup do
      @contact = Contact.make_unsaved(:florian)
    end

    context 'permitted_for' do
      setup do
        @annika = User.make(:annika)
        @benny = User.make(:benny)
        @florian = Contact.make(:florian, :user => @annika, :permission => 'Public')
        @steven = Contact.make(:steven, :user => @benny, :permission => 'Public')
      end

      should 'return all public contacts' do
        assert Contact.permitted_for(@annika).include?(@florian)
        assert Contact.permitted_for(@annika).include?(@steven)
      end

      should 'return all contacts belonging to the user' do
        @florian.update_attributes :permission => 'Private'
        assert Contact.permitted_for(@annika).include?(@florian)
      end

      should 'NOT return private contacts belonging to another user' do
        @steven.update_attributes :permission => 'Private'
        assert !Contact.permitted_for(@annika).include?(@steven)
      end

      should 'return shared contacts where the user is in the permitted users list' do
        @steven.update_attributes :permission => 'Shared', :permitted_user_ids => [@florian.user_id]
        assert Contact.permitted_for(@annika).include?(@steven)
      end

      should 'NOT return shared contacts where the user is not in the permitted users list' do
        @steven.update_attributes :permission => 'Shared', :permitted_user_ids => [@steven.user_id]
        assert !Contact.permitted_for(@annika).include?(@steven)
      end
    end

    context 'activity logging' do
      setup do
        @contact.save!
        @contact = Contact.find(@contact.id)
      end

      should 'log an activity when created' do
        assert @contact.activities.any? {|a| a.action == 'Created' }
      end

      should 'log an activity when updated' do
        @contact.update_attributes :first_name => 'test'
        assert @contact.activities.any? {|a| a.action == 'Updated' }
      end

      should 'not log an update activity when created' do
        assert_equal 1, @contact.activities.count
      end

      should 'log an activity when deleted' do
        @contact.destroy
        assert @contact.activities.any? {|a| a.action == 'Deleted' }
      end

      should 'log an activity when restored' do
        @contact.destroy
        @contact.activities.each(&:destroy)
        @contact = Contact.find(@contact.id)
        @contact.update_attributes :deleted_at => nil
        assert @contact.activities.any? {|a| a.action == 'Restored' }
      end
    end

    should 'have full name' do
      assert_equal 'Florian Behn', @contact.full_name
    end

    should 'alias full_name to name' do
      assert_equal @contact.name, @contact.full_name
    end

    should 'require at least one permitted user if permission is "Shared"' do
      @contact.permission = 'Shared'
      assert !@contact.valid?
      assert @contact.errors.on(:permitted_user_ids)
    end

    should 'require last name' do
      @contact.last_name = nil
      assert !@contact.valid?
      assert @contact.errors.on(:last_name)
    end

    should 'be valid with all required attributes' do
      assert @contact.valid?
    end
  end
end
