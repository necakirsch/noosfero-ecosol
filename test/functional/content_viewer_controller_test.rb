require File.dirname(__FILE__) + '/../test_helper'
require 'content_viewer_controller'

# Re-raise errors caught by the controller.
class ContentViewerController; def rescue_action(e) raise e end; end

class ContentViewerControllerTest < Test::Unit::TestCase

  all_fixtures

  def setup
    @controller = ContentViewerController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @profile = create_user('testinguser').person
  end
  attr_reader :profile

  def test_local_files_reference
    page = profile.articles.build(:name => 'test')
    page.save!
    assert_local_files_reference :get, :view_page, :profile => profile.identifier, :page => [ 'test' ]
  end
  
  def test_valid_xhtml
    assert_valid_xhtml
  end
  
  def test_should_display_page
    page = profile.articles.build(:name => 'test')
    page.save!

    uses_host 'anhetegua.net'
    get :view_page, :profile => profile.identifier, :page => [ 'test' ]
    assert_response :success
    assert_equal page, assigns(:page)
  end

  def test_should_display_homepage
    a = profile.articles.build(:name => 'test')
    a.save!
    profile.home_page = a
    profile.save!

    get :view_page, :profile => profile.identifier, :page => [ 'test']

    assert_response :success
    assert_template 'view_page'
    assert_equal a, assigns(:page)
  end

  def test_should_display_something_else_for_empty_homepage
    profile.articles.destroy_all

    get :view_page, :profile => profile.identifier, :page => []

    assert_response :success
    assert_template 'no_home_page'
  end

  def test_should_get_not_found_error_for_unexisting_page
    uses_host 'anhetegua.net'
    get :view_page, :profile => 'aprofile', :page => ['some_unexisting_page']
    assert_response :missing
  end

  def test_should_get_not_found_error_for_unexisting_profile
    Profile.delete_all
    uses_host 'anhetegua'
    get :view_page, :profile => 'some_unexisting_profile', :page => []
    assert_response :missing    
  end

  def test_should_be_able_to_post_comment_while_authenticated
    profile = create_user('popstar').person
    page = profile.articles.build(:name => 'myarticle', :body => 'the body of the text')
    page.save!
    profile.home_page = page; profile.save!

    assert_difference Comment, :count do
      login_as('ze')
      post :view_page, :profile => 'popstar', :page => [ 'myarticle' ], :comment => { :title => 'crap!', :body => 'I think that this article is crap' }
    end
  end

  def test_should_be_able_to_post_comment_while_not_authenticated
    profile = create_user('popstar').person
    page = profile.articles.build(:name => 'myarticle', :body => 'the body of the text')
    page.save!
    profile.home_page = page; profile.save!

    assert_difference Comment, :count do
      post :view_page, :profile => 'popstar', :page => [ 'myarticle' ], :comment => { :title => 'crap!', :body => 'I think that this article is crap', :name => 'Anonymous coward', :email => 'coward@anonymous.com' }
    end
  end

  should 'produce a download-like when article is not text/html' do

    # for example, RSS feeds 
    profile = create_user('someone').person
    page = profile.articles.build(:name => 'myarticle', :body => 'the body of the text')
    page.save!

    feed = RssFeed.new(:name => 'testfeed')
    feed.profile = profile
    feed.save!

    get :view_page, :profile => 'someone', :page => [ 'testfeed' ]

    assert_response :success
    assert_match /^text\/xml/, @response.headers['type']

    assert_equal feed.data, @response.body
  end

  should 'be able to remove comment' do
    profile = create_user('testuser').person
    article = profile.articles.build(:name => 'test')
    article.save!
    comment = article.comments.build(:author => profile, :title => 'a comment', :body => 'lalala')
    comment.save!

    login_as 'testuser'
    assert_difference Comment, :count, -1 do
      post :view_page, :profile => profile.identifier, :page => [ 'test' ], :remove_comment => comment.id
      assert_response :redirect
    end
    
  end
  
  should "not be able to remove other people's comments" do
    profile = create_user('testuser').person
    article = profile.articles.build(:name => 'test')
    article.save!
    
    commenter = create_user('otheruser').person
    comment = article.comments.build(:author => commenter, :title => 'a comment', :body => 'lalala')
    comment.save!

    login_as 'ze' # ze cannot remove other people's comments
    assert_no_difference Comment, :count do 
      post :view_page, :profile => profile.identifier, :page => [ 'test' ], :remove_comment => comment.id
      assert_response :redirect
    end
    
  end

  should 'be able to remove comments on their articles' do
    profile = create_user('testuser').person
    article = profile.articles.build(:name => 'test')
    article.save!
    
    commenter = create_user('otheruser').person
    comment = article.comments.build(:author => commenter, :title => 'a comment', :body => 'lalala')
    comment.save!

    login_as 'testuser' # testuser must be able to remove comments in his articles
    assert_difference Comment, :count, -1 do 
      post :view_page, :profile => profile.identifier, :page => [ 'test' ], :remove_comment => comment.id
      assert_response :redirect
    end

  end

  should 'not be able to post comment while inverse captcha field filled' do
    profile = create_user('popstar').person
    page = profile.articles.build(:name => 'myarticle', :body => 'the body of the text')
    page.save!
    profile.home_page = page; profile.save!

    assert_no_difference Comment, :count do
      post :view_page, :profile => profile.identifier, :page => [ 'myarticle' ], @controller.icaptcha_field => 'filled', :comment => { :title => 'crap!', :body => 'I think that this article is crap', :name => 'Anonymous coward', :email => 'coward@anonymous.com' }
    end
  end

  should 'render inverse captcha field' do
    profile = create_user('popstar').person
    page = profile.articles.build(:name => 'myarticle', :body => 'the body of the text')
    page.save!
    profile.home_page = page; profile.save!
    get :view_page, :profile => profile.identifier, :page => [ 'myarticle' ]
    assert_tag :tag => 'input', :attributes => { :type => 'text', :name => @controller.icaptcha_field }
  end

  should 'show error messages when make a blank comment' do
    login_as @profile.identifier
    page = profile.articles.create!(:name => 'myarticle', :body => 'the body of the text')
    post :view_page, :profile => @profile.identifier, :page => [ 'myarticle' ], :comment => { :title => '', :body => '' }
    assert_tag :tag => 'div', :attributes => { :class => 'errorExplanation', :id => 'errorExplanation' }
  end

  should 'show comment form opened on error' do
    login_as @profile.identifier
    page = profile.articles.create!(:name => 'myarticle', :body => 'the body of the text')
    post :view_page, :profile => @profile.identifier, :page => [ 'myarticle' ], :comment => { :title => '', :body => '' }
    assert_tag :tag => 'div', :attributes => { :class => 'post_comment_box opened' }
  end
  
  should 'filter html content from body' do
    login_as @profile.identifier
    page = profile.articles.create!(:name => 'myarticle', :body => 'the body of the text')
    post :view_page, :profile => @profile.identifier, :page => [ 'myarticle' ],
      :comment => { :title => 'html comment', :body => "this is a <strong id='html_test_comment'>html comment</strong>" }
    assert_no_tag :tag => 'strong', :attributes => { :id => 'html_test_comment' }
  end

  should 'filter html content from title' do
    login_as @profile.identifier
    page = profile.articles.create!(:name => 'myarticle', :body => 'the body of the text')
    post :view_page, :profile => @profile.identifier, :page => [ 'myarticle' ],
      :comment => { :title => "html <strong id='html_test_comment'>comment</strong>", :body => "this is a comment" }
    assert_no_tag :tag => 'strong', :attributes => { :id => 'html_test_comment' }
  end

  should "display current article's tags" do
    page = profile.articles.create!(:name => 'myarticle', :body => 'test article', :tag_list => 'tag1, tag2')

    get :view_page, :profile => profile.identifier, :page => [ 'myarticle' ]
    assert_tag :tag => 'div', :attributes => { :class => 'article-tags' }, :descendant => {
      :tag => 'a',
      :attributes => { :href => "/profile/#{profile.identifier}/tag/tag1" }
    }
    assert_tag :tag => 'div', :attributes => { :class => 'article-tags' }, :descendant => {
      :tag => 'a',
      :attributes => { :href => "/profile/#{profile.identifier}/tag/tag2" }
    }

    assert_tag :tag => 'div', :attributes => { :class => 'article-tags' }, :descendant => { :content => /This article's tags:/ }
  end

  should 'not display articles from private content' do
    profile.articles.create!(:name => 'test')
    profile.update_attributes!(:public_content => false)

    get :view_page, :profile => profile.identifier, :page => [ 'test' ]
    assert_response 403
  end

  #should 'display articles to its owner' do
    #profile.articles.create!(:name => 'test')
    #profile.update_attributes!(:public_content => false)

    #login_as(@profile.identifier)
    #get :view_page, :profile => profile.identifier, :page => [ 'test' ]
    #assert_response 200
  #end

  #should 'display articles to profile members' do
    #c = Community.create!(:name => 'my community')
    #c.update_attributes!(:public_content => false)
    #c.add_member(@profile)

    #login_as(@profile.identifier)
    #get :view_page, :profile => profile.identifier, :page => [ 'test' ]
    #assert_response 200
  #end

end
