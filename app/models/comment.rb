class Comment
  include Mongoid::Document
  include Mongoid::Timestamps
  include HasConstant
  include HasConstant::Orm::Mongoid
  include Activities
  include Permission
  include ParanoidDelete

  field :subject
  field :text

  named_scope :sorted, :order => 'created_at asc'

  belongs_to_related :user
  belongs_to_related :commentable, :polymorphic => true

  has_many_related :attachments, :as => :subject

  validates_presence_of :commentable, :user, :text

  after_create :add_attachments

  def name
    "#{text[0..30]}..."
  end

  def attachments_attributes=( attribs )
    @attachments_to_add = []
    attribs.each do |hash|
      @attachments_to_add << hash
    end if attribs
  end

protected
  def add_attachments
    @attachments_to_add.each do |a|
      self.attachments.create(a)
    end if @attachments_to_add
  end
end
