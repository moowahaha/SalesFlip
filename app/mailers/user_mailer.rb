class UserMailer < ActionMailer::Base
  default :from => 'do-not-reply@salesflip.com'

  def tracked_items_update( user )
    @user   = user
    @items  = user.tracked_items
    mail(:to => user.email, :subject => I18n.t('emails.tracked_items_update.subject',
                                               :date => Date.today.to_s(:long)))
  end

  def lead_assignment_notification( lead )
    @lead = lead
    mail(:to => lead.assignee.email, :subject => I18n.t('emails.lead_assignment.subject'))
  end
end
