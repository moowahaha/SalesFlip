class InvitationMailer < ActionMailer::Base
  default :from => 'Do Not Reply <mattbeedle@googlemail.com>'

  def invitation( invitation )
    @invitation = invitation
    mail(:to => invitation.email, :subject => I18n.t('emails.invitation.subject'),
         :reply_to => 'do-not-reply@salesflip.com')
  end
end
