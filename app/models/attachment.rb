class Attachment
  include Mongoid::Document
  include Mongoid::Timestamps

  field :attachment

  belongs_to_related :subject, :polymorphic => true

  validates_presence_of :subject
  validate :validate_attachment

  mount_uploader :attachment, AttachmentUploader

protected
  def validate_attachment
    if self.attachment.blank?
      self.errors.add :attachment, I18n.t('active_record.errors.messages.blank')
    end
  end
end
