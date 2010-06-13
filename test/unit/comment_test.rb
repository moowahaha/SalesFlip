require 'test_helper.rb'

class CommentTest < ActiveSupport::TestCase
  

  context 'Named Scopes' do
    context "sorted" do
      should 'sort by creation date in ascending order' do
        @comment_2 = Comment.make(:created_at => 5.minutes.ago)
        @comment_1 = Comment.make(:created_at => 10.minutes.ago)
        @comment_3 = Comment.make(:created_at => 2.minutes.ago)
        assert_equal [@comment_1,@comment_2,@comment_3], Comment.sorted
      end
    end
  end

  
  context 'Instance' do
    setup do
      @comment = Comment.make_unsaved(:made_offer_to_erich)
    end

    should 'return first 60 characters of text for name' do
      assert_equal "#{@comment.text[0..30]}...", @comment.name
    end

    should 'be valid with all required attributes' do
      assert @comment.valid?
    end

    should 'not be valid without user' do
      @comment.user_id = nil
      assert !@comment.valid?
      assert @comment.errors[:user_id]
    end

    should 'not be valid without commentable' do
      @comment.commentable = nil
      assert !@comment.valid?
      assert @comment.errors[:commentable]
    end
  end
end
