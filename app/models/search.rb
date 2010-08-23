class Search
  include Mongoid::Document
  include Mongoid::Timestamps

  field :terms
  field :collections, :type => Array
  field :company

  belongs_to_related :user

  validate :criteria_entered?

  def results
    unless company.blank?
      @results ||= Lead.search { with(:company, company) }.results.not_deleted +
        Account.search { with(:name, company) }.results.not_deleted
    else
      @results ||= Sunspot.search([Account, Contact, Lead]) do
        keywords terms
      end.results
    end
  end

private
  def criteria_entered?
    if self.terms.blank? and self.company.blank?
      self.errors.add :terms, I18n.t('activerecord.errors.messages.blank')
      self.errors.add :company, I18n.t('activerecord.errors.messages.blank')
    end
  end
end
