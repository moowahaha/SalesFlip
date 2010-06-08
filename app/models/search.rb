class Search
  include Mongoid::Document
  include Mongoid::Timetamps

  field :terms
  field :collections, :type => Array
  field :company

  belongs_to_related :user

  validate :criteria_entered?

  def results
    unless company.blank?
      @results ||= Lead.search(company, :keys_to_search => 'company').not_deleted +
        Account.search(company, :keys_to_search => 'name').not_deleted
    else
      @results ||= (collections.blank? ? %w(Lead, Contact, Account) : collections).map do |klass|
        klass.constantize.search(terms).not_deleted
      end.inject { |sum,n| sum += n }
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
