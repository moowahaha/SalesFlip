# encoding: utf-8
require 'test_helper.rb'

class EmailReaderTest < ActiveSupport::TestCase

  context 'when email is outgoing, encoded in "iso-8859-1" with weird german ä characters' do
    setup do
      @user = User.make(:annika, :email => 'annika.fleischer@1000jobboersen.de')
      @email = Mail.new(File.read("#{Rails.root}/test/support/direct_email_in_latin1.txt").strip)
    end

    context 'when receiver does not exist' do
      setup do
        EmailReader.parse_email(@email)
      end

      should 'decode ä characters properly' do
        assert_match(/ä/, Email.first.text)
      end

      should 'set from address' do
        assert_equal @user.email, Email.first.from
      end
    end
  end

  context "when email is outgoing (bcc'd)" do
    setup do
      @user = User.make(:annika, :email => 'mattbeedle@googlemail.com')
      @email = Mail.new(
        File.read("#{Rails.root}/test/support/direct_email_with_attachment.txt").strip
      )
    end

    context 'when sent to a single receiver' do
      setup do
        @email.stubs(:to).returns(['test@test.com'])
      end

      context 'when receiver exists as an account' do
        setup do
          @account = Account.make(:careermee, :email => 'test@test.com')
          EmailReader.parse_email(@email)
        end

        should 'add comment to account' do
          assert_equal 1, @account.comments.count
        end
      end

      context 'when receiver exists as a lead' do
        setup do
          @lead = Lead.make(:erich, :email => 'test@test.com')
          EmailReader.parse_email(@email)
        end

        should 'add comment to lead' do
          assert_equal 1, @lead.comments.length
        end

        should 'populate comment text from email body' do
          assert_equal @email.parts.first.parts.first.body.to_s, @lead.comments.first.text
        end

        should 'populate comment user from user found from email "from" address' do
          assert_equal @user, @lead.comments.first.user
        end

        should 'save attachments against comment' do
          assert_equal 1, @lead.comments.first.attachments.length
        end

        should 'mark comment as "from_email"' do
          assert @lead.comments.first.from_email
        end
      end

      context 'when receiver exists as a contact' do
        setup do
          @contact = Contact.make(:florian, :email => 'test@test.com')
          EmailReader.parse_email(@email)
        end

        should 'add comment to contact' do
          assert_equal 1, @contact.comments.length
        end
      end

      context 'when receiver does not exist' do
        setup do
          EmailReader.parse_email(@email)
        end

        should 'create contact and add comment to it' do
          assert_equal 1, Contact.count
          assert Contact.first(:conditions => { :email => @email.to })
        end

        should 'create an account' do
          assert_equal 1, Account.count
        end
      end

      context 'when receiver exists as an account and a contact and a lead' do
        setup do
          @account = Account.make(:careermee, :email => 'test@test.com')
          @contact = Contact.make(:florian, :email => 'test@test.com')
          @lead = Lead.make(:erich, :email => 'test@test.com')
        end

        context 'when lead is new' do
          setup do
            @lead.update_attributes :status => 'New'
            EmailReader.parse_email(@email)
          end

          should 'add comment to lead' do
            assert_equal 1, @lead.comments.count
          end

          should 'not add comment to account or contact' do
            assert_equal 0, @contact.comments.count
            assert_equal 0, @account.comments.count
          end
        end

        context 'when lead is converted' do
          setup do
            @lead.update_attributes :status => 'Converted'
            EmailReader.parse_email(@email)
          end

          should 'add comment to contact' do
            assert_equal 1, @contact.comments.count
          end

          should 'not add comment to account or lead' do
            assert_equal 0, @account.comments.count
            assert_equal 0, @lead.comments.count
          end
        end
      end
    end
  end

  context "when email is forwarded, but the forwarded message was an outgoing message" do
    setup do
      @user = User.make(:annika, :email => 'matt.beedle@1000jobboersen.de')
      @email = Mail.new(File.read("#{Rails.root}/test/support/forwarded_outgoing.txt").strip)
      @email.stubs(:to).returns(["dropbox@#{@user.api_key}.1000jobboersen.de"])
    end

    context 'when receiver exists as a lead' do
      setup do
        @lead = Lead.make(:erich, :email => 'mattbeedle@gmail.com')
        EmailReader.parse_email(@email)
      end

      should 'add comment to lead' do
        assert_equal 1, @lead.comments.count
        assert_equal @email.parts.first.body.to_s, @lead.comments.first.text
      end

      should 'add attachments to comment' do
        assert_equal 1, @lead.comments.first.attachments.count
      end
    end

    context 'when receiver exists as a contact' do
      setup do
        @contact = Contact.make(:florian, :email => 'mattbeedle@gmail.com')
        EmailReader.parse_email(@email)
      end

      should 'add comment to contact' do
        assert_equal 1, @contact.comments.count
        assert_equal @email.parts.first.body.to_s, @contact.comments.first.text
      end

      should 'add attachments to comment' do
        assert_equal 1, @contact.comments.first.attachments.count
      end
    end

    context 'when receiver does not exist' do
      setup do
        EmailReader.parse_email(@email)
      end

      should 'create a new contact' do
        assert_equal 1, Contact.count
      end

      should 'add attachments to comment' do
        assert_equal 1, Comment.first.attachments.count
      end

      should 'create an account' do
        assert_equal 1, Account.count
      end
    end
  end

  context 'when email is incoming (forwarded)' do
    setup do
      @user = User.make(:annika)
      @email = Mail.new(File.read("#{Rails.root}/test/support/forwarded_reply.txt").strip)
      @email.stubs(:to).returns(["dropbox@#{@user.api_key}.1000jobboersen.de"])
    end

    context 'when sender exists as a lead' do
      setup do
        @lead = Lead.make(:erich, :email => 'mattbeedle@googlemail.com')
        EmailReader.parse_email(@email)
      end

      should 'add comment to lead' do
        assert_equal 1, @lead.comments.count
        assert_equal @email.body.to_s, @lead.comments.first.text
      end
    end

    context 'when sender exists as a contact' do
      setup do
        @contact = Contact.make(:florian, :email => 'mattbeedle@googlemail.com')
        EmailReader.parse_email(@email)
      end

      should 'add comment to contact' do
        assert_equal 1, @contact.comments.count
      end
    end

    context 'when sender does not exist' do
      setup do
        EmailReader.parse_email(@email)
      end

      should 'create contact and add comment to it' do
        assert_equal 1, Contact.count
        assert_equal 1, Contact.first.comments.count
        assert_equal 'mattbeedle@googlemail.com', Contact.first.email
      end
    end
  end

  context "when replying and bcc'ing" do
    setup do
      @user = User.make(:annika, :email => 'matt.beedle@1000jobboersen.de')
      @email = Mail.new(File.read("#{Rails.root}/test/support/replying_and_bcc_ing.txt"))
    end

    context 'when the lead exists' do
      setup do
        @lead = Lead.make(:erich, :email => 'mattbeedle@googlemail.com')
        EmailReader.parse_email(@email)
      end

      should 'add comment to lead' do
        assert_equal 1, @lead.comments.length
        assert_equal 'Re: this is just a test', @lead.comments.first.subject
        assert_match(/ok, and now I am replying again./, @lead.comments.first.text)
      end
    end

    context 'when the contact exists' do
      setup do
        @contact = Contact.make(:florian, :email => 'mattbeedle@googlemail.com')
        EmailReader.parse_email(@email)
      end

      should 'add comment to contact' do
        assert_equal 1, @contact.comments.length
        assert_equal 'Re: this is just a test', @contact.comments.first.subject
        assert_match(/ok, and now I am replying again./, @contact.comments.first.text)
      end
    end

    context 'when the lead/contact does not exist' do
      setup do
        EmailReader.parse_email(@email)
      end

      should 'create a new contact' do
        assert_equal 1, Contact.count
      end

      should 'add comment to contact' do
        assert_equal 1, Contact.first.comments.count
      end

      should 'actually create the comment as an email' do
        assert_equal 1, Email.count
      end

      should 'create an account' do
        assert_equal 1, Account.count
      end
    end
  end

  context 'when forwarding a reply to my reply' do
    setup do
      @user = User.make(:annika, :email => 'matt.beedle@1000jobboersen.de')
      @email = Mail.new(
        File.read("#{Rails.root}/test/support/forwarding_reply_to_my_reply_to_dropbox.txt")
      )
    end

    context 'when the contact exists' do
      setup do
        @contact = Contact.make(:florian, :email => 'mattbeedle@googlemail.com')
        EmailReader.parse_email(@email)
      end

      should 'add comment to contact' do
        assert_equal 1, @contact.comments.count
      end

      should 'actually add comment as an email' do
        assert @contact.comments.first.is_a?(Email)
      end
    end

    context 'when the lead exists' do
      setup do
        @lead = Lead.make(:erich, :email => 'mattbeedle@googlemail.com')
        EmailReader.parse_email(@email)
      end

      should 'add comment to lead' do
        assert_equal 1, @lead.comments.count
      end

      should 'actually add comment as an email' do
        assert @lead.comments.first.is_a?(Email)
      end
    end

    context 'when comment/lead does not exist' do
      setup do
        EmailReader.parse_email(@email)
      end

      should 'create a new contact' do
        assert_equal 1, Contact.count
        assert_equal 'mattbeedle@googlemail.com', Contact.first.email
      end

      should 'add comment to contact (as an email)' do
        assert_equal 1, Contact.first.comments.count
        assert Contact.first.comments.first.is_a?(Email)
      end

      should 'create an account' do
        assert_equal 1, Account.count
      end
    end
  end
end
