require 'test_helper.rb'

class ContactTest < ActiveSupport::TestCase
  context "Class" do
    should_have_key :identifier, :city, :postal_code, :country, :job_title, :department
    should_have_constant :accesses, :titles, :permissions, :salutations, :sources
    should_act_as_paranoid
    should_be_trackable
    should_belong_to :account, :user, :assignee
    should_have_many :leads, :tasks, :comments

    should 'know which fields can be exported' do
      Contact.fields.map(&:first).each do |field|
        unless field == 'access' || field == 'permission' ||
          field == 'permitted_user_ids' || field == 'tracker_ids'
          assert Contact.exportable_fields.include?(field)
        else
          assert !Contact.exportable_fields.include?(field)
        end
      end
    end

    context 'create_for' do
      setup do
        @account = Account.make(:careermee)
        @lead = Lead.make(:call_erich, :user => @account.user)
      end

      should 'create a contact from the supplied lead and account' do
        Contact.create_for(@lead, @account)
        assert_equal 1, Contact.count
        assert Contact.where(:first_name => @lead.first_name, :last_name => @lead.last_name).first
        assert_equal 1, @account.contacts.count
      end

      should 'assign lead to contact' do
        contact = Contact.create_for(@lead, @account)
        assert contact.leads.include?(@lead)
      end

      should 'not create the contact if the supplied account is invalid' do
        @account.name = nil
        contact = Contact.create_for(@lead, @account)
        assert_equal 0, Contact.count
      end

      should 'copy all lead attributes that can be copied' do
        5.times do
          Identifier.next_contact
        end
        @lead.update_attributes :phone => '1234567890', :salutation => 'Mr',
          :department => 'a test department', :source => 'Website', :address => 'an address',
          :website => 'www.test.com', :linked_in => 'linkedin', :facebook => 'facebook',
          :xing => 'xing', :do_not_call => true
        contact = Contact.create_for(@lead, @account)
        assert_equal '1234567890', contact.phone
        assert_equal 'Mr', contact.salutation
        assert_equal 'a test department', contact.department
        assert_equal 'Website', contact.source
        assert_equal 'an address', contact.address
        assert_equal 'www.test.com', contact.website
        assert_equal 'linkedin', contact.linked_in
        assert_equal 'facebook', contact.facebook
        assert_equal 'xing', contact.xing
        assert contact.identifier != @lead.identifier
        assert contact.do_not_call
      end
    end
  end

  context 'Named scopes' do
    context 'for_company' do
      setup do
        @contact = Contact.make
        @contact2 = Contact.make
      end

      should 'only return contacts for the supplied company' do
        assert_equal @contact, Contact.for_company(@contact.user.company).first
        assert_equal 1, Contact.for_company(@contact.user.company).count
        assert_equal @contact2, Contact.for_company(@contact2.user.company).first
        assert_equal 1, Contact.for_company(@contact2.user.company).count
      end
    end
  end

  context "Instance" do
    setup do
      @contact = Contact.make_unsaved(:florian, :user => User.make(:annika))
    end

    should 'be able to get fields in pipe deliminated format' do
      assert_equal @contact.deliminated('|', ['first_name', 'last_name']), "Florian|Behn"
    end

    should 'be assigned an identifier on creation' do
      assert @contact.identifier.nil?
      @contact.save!
      assert @contact.identifier
    end

    should 'be assigned consecutive identifiers' do
      @contact.save!
      assert_equal 1, @contact.identifier
      @contact2 = Contact.make_unsaved
      assert @contact2.identifier.nil?
      @contact2.save!
      assert_equal 2, @contact2.reload.identifier
    end

    should 'validate uniqueness of email' do
      @contact.email = 'florian.behn@careermee.com'
      @contact.save!
      c = Contact.make_unsaved(:florian, :email => @contact.email)
      assert !c.valid?
      assert c.errors[:email]
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

      should 'not log an "update" activity when do_not_log is set' do
        @contact.update_attributes :first_name => 'test', :do_not_log => true
        assert !@contact.activities.any? {|a| a.action == 'Updated' }
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

    context 'listing_name' do
      should 'return last name, then first name' do
        assert_equal 'Behn, Florian', @contact.listing_name
      end

      should 'have no comma if there is no first name' do
        @contact.first_name = nil
        assert_equal 'Behn', @contact.listing_name
      end
    end

    should 'alias full_name to name' do
      assert_equal @contact.name, @contact.full_name
    end

    should 'require at least one permitted user if permission is "Shared"' do
      @contact.permission = 'Shared'
      assert !@contact.valid?
      assert @contact.errors[:permitted_user_ids]
    end

    should 'require last name' do
      @contact.last_name = nil
      assert !@contact.valid?
      assert @contact.errors[:last_name]
    end

    should 'be valid with all required attributes' do
      assert @contact.valid?
    end
  end
end
