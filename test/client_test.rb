require 'test_helper'
require 'date'

class ClientTest < Test

  APP_URL = 'http://example.com'
  APP_NAME = 'Akismet tests'

  def setup
    @client = Akismet::Client.new( API_KEY,
      APP_URL,
      app_name: APP_NAME,
      app_version: Akismet::VERSION )

    @invalid_client = Akismet::Client.new( 'invalid-api-key',
      APP_URL,
      app_name: APP_NAME,
      app_version: Akismet::VERSION )
  end

  def test_attrs
    assert_equal @client.api_key, API_KEY
    assert_equal @client.app_url, APP_URL
    assert_equal @client.app_name, 'Akismet tests'
    assert_equal @client.app_version, Akismet::VERSION
  end

  def test_verify_key_with_valid_key_returns_true
    assert_equal true, @client.verify_key
  end

  def test_verify_key_with_invalid_key_returns_false
    assert_equal false, @invalid_client.verify_key
  end

  def test_check_with_invalid_api_key_raises
    assert_raises( Akismet::Error ) do
      @invalid_client.comment_check 'ip', 'ua'
    end
  end

  # Akismet returns true when author == 'viagra-test-123'
  def test_check_with_spam_returns_true
    spam, _ = @client.check('ip', 'ua', author: 'viagra-test-123')
    assert_equal true, spam
  end

  # Akismet returns false when user_role == 'administrator'
  def test_check_with_ham_returns_false
    spam, _ = @client.check('ip', 'ua', user_role: 'administrator')
    assert_equal false, spam
  end

  def test_check_with_all_params_succeeds
    @client.check 'ip', 'ua',
      type: 'comment',
      text: 'hello',
      created_at: DateTime.now,
      author: 'author',
      author_url: 'http://example.com',
      author_email: 'joe@example.com',
      post_url: 'http://example.com/posts/1',
      post_modified_at: DateTime.now,
      languages: %w{en fr},
      referrer: 'http://example.com',
      env: {a: 1, b: 1},
      user_role: 'Administrator',
      test: true
  end

  # Akismet returns true when author == 'viagra-test-123'
  def test_spam_predicate_with_spam_returns_true
    assert_equal true, @client.spam?('ip', 'ua', author: 'viagra-test-123')
  end

  # Akismet returns false when user_role == 'administrator'
  def test_spam_predicate_with_ham_returns_false
    assert_equal false, @client.spam?('ip', 'ua', user_role: 'administrator')
  end

  def test_spam_predicate_with_invalid_api_key_raises
    assert_raises( Akismet::Error ) do
      @invalid_client.spam? 'ip', 'ua'
    end
  end

  def test_ham_succeeds
    @client.ham 'ip', 'ua', text: 'hello'
  end

  def test_ham_with_invalid_api_key_raises
    assert_raises( Akismet::Error ) do
      @invalid_client.ham 'ip', 'ua'
    end
  end

  def test_spam_succeeds
    @client.spam 'ip', 'ua', test: 'hello'
  end

  def test_spam_with_invalid_api_key_raises
    assert_raises( Akismet::Error ) do
      @invalid_client.spam 'ip', 'ua'
    end
  end

  def test_open_opens_client
    refute @client.open?
    @client.open
    assert @client.open?
    @client.close
  end

  def test_open_with_block_opens_then_closes_client
    refute @client.open?
    @client.open { assert @client.open? }
    refute @client.open?
  end

  def test_open_raises_when_client_open
    assert !@client.open?
    @client.open
    assert @client.open?
    assert_raises( RuntimeError ) { @client.open }
  end

  def test_close_closes_client
    @client.open
    assert @client.open?
    @client.close
    refute @client.open?
  end

  def test_close_succeeds_when_client_closed
    assert !@client.open?
    @client.close
  end

  def test_class_open_yields_open_client
    Akismet::Client.open( API_KEY, APP_URL ) do |client|
      assert client.is_a?( Akismet::Client )
      assert client.open?
    end
  end

  def test_conflicting_env_var_raises
    assert_raises(ArgumentError) do
      @client.check 'ip', 'ua', env: { referrer: 'referrer' }
    end
  end

  def test_invalid_param_raises
    assert_raises(ArgumentError) do
      @client.check 'ip', 'ua', invalid_param: 'invalid'
    end
  end

end