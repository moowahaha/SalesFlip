class Comment
  include MongoMapper::Document
  include HasConstant
  include Activities
  include Permission
  include ParanoidDelete

  key :user_id,           ObjectId, :required => true, :index => true
  key :commentable_id,    ObjectId, :index => true
  key :commentable_type,  String, :index => true
  key :subject,           String
  key :text,              String, :required => true
  key :_type,             String
  timestamps!
  
  named_scope :sorted, :order => 'created_at asc'
  
  belongs_to :user
  belongs_to :commentable, :polymorphic => true

  has_many :attachments, :as => :subject

  validates_presence_of :commentable

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
