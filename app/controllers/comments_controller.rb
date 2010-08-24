class CommentsController < InheritedResources::Base

  respond_to :html
  respond_to :xml

  def create
    create! do |success, failure|
      success.html do
        return_to_or_default commentable_path
      end
    end
  end

  def update
    update! do |success, failure|
      success.html do
        flash[:notice] = I18n.t('comment_updated')
        return_to_or_default commentable_path
      end
    end
  end

  def destroy
    destroy! do |success, failure|
      success.html { return_to_or_default commentable_path }
    end
  end

protected
  def commentable_path
    url_for(
      :controller => @comment.commentable.class.to_s.downcase.pluralize,
      :action     => 'show',
      :id         => @comment.commentable.id
    )
  end
  
  def begin_of_association_chain
    current_user
  end
end
