module ParanoidDelete
  def self.included( base )
    base.send(:include, InstanceMethods)
    base.class_eval do
      field :deleted_at, :type => Time

      named_scope :not_deleted, :where => { :deleted_at => nil }
      named_scope :deleted, :where => { :deleted_at => { '$ne' => nil } }

      alias_method_chain :destroy, :paranoid
    end
  end

  module InstanceMethods
    def destroy_with_paranoid
      @recently_destroyed = true
      update_attributes :deleted_at => Time.now
    end

    def destroy
      comments.all.each(&:destroy_without_paranoid) if self.respond_to?(:comments)
      super
    end

    def deleted_at=( value )
      original_value = self.deleted_at
      self[:deleted_at] = value
      @recently_restored = true if !original_value.nil? && self.deleted_at.nil?
    end
  end
end
