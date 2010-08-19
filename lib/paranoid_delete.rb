module ParanoidDelete
  def self.included( base )
    base.send(:include, InstanceMethods)
    base.class_eval do
      field :deleted_at, :type => Time

      named_scope :not_deleted, :where => { :deleted_at => nil }
      named_scope :deleted, :where => { :deleted_at => { '$ne' => nil } }

      alias_method_chain :destroy, :paranoid
      before_save :recently_restored?
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

    def recently_restored?
      @recently_restored = true if changed.include?('deleted_at') && !self.deleted_at
    end
  end
end
