class InvitationMailer < ActionMailer::Base
  def invitation( invitation )
    recipients  invitation.email
    from        I18n.t('emails.do_not_reply', :host => 'salesflip.com')
    subject     I18n.t('emails.invitation.subject')
    sent_on     Time.now
    body        :invitation => invitation
  end
end
