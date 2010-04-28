class Search
  include MongoMapper::Document

  key :terms,       String
  key :user_id,     ObjectId
  key :collections, Array
  key :company,     String
  timestamps!

  belongs_to :user

  validate :criteria_entered?

  def results
    unless company.blank?
      @results ||= Lead.scoped(:conditions => { :id => Lead.search("@company #{company}").
                               map(&:id) }).not_deleted +
        Account.scoped(:conditions => { :id => Account.search("@name #{company}").map(&:id) }).
        not_deleted
    else
      @results ||= (collections.blank? ? %w(Lead, Contact, Account) : collections).map do |klass|
        klass = klass.constantize
        klass.scoped(:conditions => { :id => klass.search(terms).map(&:id) }).not_deleted
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
