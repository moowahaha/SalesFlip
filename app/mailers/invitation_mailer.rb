class InvitationMailer < ActionMailer::Base
  default :from => 'do-not-reply@salesflip.com'

  def invitation( invitation )
    @invitation = invitation
    mail(:to => invitation.email, :subject => I18n.t('emails.invitation.subject'))
  end
end
