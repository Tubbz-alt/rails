require 'abstract_unit'
require 'fixtures/post'
require 'fixtures/comment'
require 'fixtures/author'
require 'fixtures/category'
require 'fixtures/company'

class EagerAssociationTest < Test::Unit::TestCase
  fixtures :posts, :comments, :authors, :categories, :categories_posts,
            :companies, :accounts

  def test_loading_with_one_association
    posts = Post.find(:all, :include => :comments)
    assert_equal 2, posts.first.comments.size
    assert posts.first.comments.include?(comments(:greetings))

    post = Post.find(:first, :include => :comments, :conditions => "posts.title = 'Welcome to the weblog'")
    assert_equal 2, post.comments.size
    assert post.comments.include?(comments(:greetings))
  end

  def test_with_ordering
    posts = Post.find(:all, :include => :comments, :order => "posts.id DESC")
    assert_equal posts(:sti_habtm), posts[0]
    assert_equal posts(:sti_post_and_comments), posts[1]
    assert_equal posts(:sti_comments), posts[2]
    assert_equal posts(:authorless), posts[3]
    assert_equal posts(:thinking), posts[4]
    assert_equal posts(:welcome), posts[5]
  end
  
  def test_loading_with_multiple_associations
    posts = Post.find(:all, :include => [ :comments, :author, :categories ], :order => "posts.id")
    assert_equal 2, posts.first.comments.size
    assert_equal 2, posts.first.categories.size
    assert posts.first.comments.include?(comments(:greetings))
  end

  def test_loading_from_an_association
    posts = authors(:david).posts.find(:all, :include => :comments, :order => "posts.id")
    assert_equal 2, posts.first.comments.size
  end

  def test_loading_with_no_associations
    assert_nil Post.find(posts(:authorless).id, :include => :author).author
  end

  def test_eager_association_loading_with_belongs_to
    comments = Comment.find(:all, :include => :post)
    titles = comments.map { |c| c.post.title }
    assert titles.include?(posts(:welcome).title)
    assert titles.include?(posts(:sti_post_and_comments).title)
  end

  def test_eager_association_loading_with_habtm
    posts = Post.find(:all, :include => :categories, :order => "posts.id")
    assert_equal 2, posts[0].categories.size
    assert_equal 1, posts[1].categories.size
    assert_equal 0, posts[2].categories.size
    assert posts[0].categories.include?(categories(:technology))
    assert posts[1].categories.include?(categories(:general))
  end
  
  def test_eager_with_inheritance
    posts = SpecialPost.find(:all, :include => [ :comments ])
  end  

  def test_eager_has_one_with_association_inheritance
    post = Post.find(4, :include => [ :very_special_comment ])
    assert_equal "VerySpecialComment", post.very_special_comment.class.to_s
  end  
  
  def test_eager_has_many_with_association_inheritance
    post = Post.find(4, :include => [ :special_comments ])
    post.special_comments.each do |special_comment|
      assert_equal "SpecialComment", special_comment.class.to_s
    end
  end  
  
  def test_eager_habtm_with_association_inheritance
    post = Post.find(6, :include => [ :special_categories ])
    assert_equal 1, post.special_categories.size
    post.special_categories.each do |special_category|
      assert_equal "SpecialCategory", special_category.class.to_s
    end
  end

  def test_eager_with_has_one_dependent_does_not_destroy_dependent
    assert_not_nil companies(:first_firm).account
    f = Firm.find(:first, :include => :account,
            :conditions => ["companies.name = ?", "37signals"])
    assert_not_nil companies(:first_firm, :reload).account
  end
end

