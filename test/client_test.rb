require 'test_helper'

class ClientTest < MiniTest::Unit::TestCase

  # jonahb2's key
  API_KEY = 'ecd2022d3247'
  HOME_URL = 'http://example.com'
  APP_NAME = 'Akismet tests'

  def setup
    @client = Akismet::Client.new( API_KEY,
      HOME_URL,
      :app_name => APP_NAME,
      :app_version => Akismet::VERSION )

    @invalid_client = Akismet::Client.new( 'invalid-api-key',
      HOME_URL,
      :app_name => APP_NAME,
      :app_version => Akismet::VERSION )
  end

  def test_attrs
    assert_equal @client.api_key, API_KEY
    assert_equal @client.home_url, HOME_URL
    assert_equal @client.app_name, 'Akismet tests'
    assert_equal @client.app_version, Akismet::VERSION
  end

  def test_verify_key_succeeds_with_valid_key
    assert @client.verify_key
  end

  def test_verify_key_fails_with_invalid_key
    assert !@invalid_client.verify_key
  end

  def test_comment_check_with_invalid_api_key_raises
    error = assert_raises( Akismet::Error ) do
      @invalid_client.comment_check 'ip', 'ua'
    end
    assert_equal Akismet::Error::INVALID_API_KEY, error.code
  end

  # Akismet always returns true when comment_check is called with the
  # author 'viagra-test-123'
  def test_comment_check_with_spam_returns_true
    assert @client.comment_check( 'ip',
      'ua',
      :author => 'viagra-test-123' )
  end

  def test_submit_ham_with_invalid_api_key_raises
    error = assert_raises( Akismet::Error ) do
      @invalid_client.submit_ham 'ip', 'ua'
    end
    assert_equal Akismet::Error::INVALID_API_KEY, error.code
  end

  def test_submit_ham_returns_nil
    assert_nil @client.submit_ham( 'ip', 'ua' )
  end

  def test_submit_spam_with_invalid_api_key_raises
    error = assert_raises( Akismet::Error ) do
      @invalid_client.submit_spam 'ip', 'ua'
    end
    assert_equal Akismet::Error::INVALID_API_KEY, error.code
  end

  def test_submit_spam_returns_nil
    assert_nil @client.submit_spam 'ip', 'ua'
  end

  def test_class_open
    Akismet::Client.open( API_KEY, HOME_URL ) do |client|
      assert client.is_a?( Akismet::Client )
      assert client.open?
    end
  end

  def test_open_with_block_opens_then_closes_client
    refute @client.open?
    @client.open { assert @client.open? }
    refute @client.open?
  end

  def test_instance_open_close
    assert !@client.open?
    @client.open
    assert @client.open?
    @client.close
    assert !@client.open?
  end

  def test_open_raises_when_client_open
    assert !@client.open?
    @client.open
    assert @client.open?
    assert_raises( RuntimeError ) { @client.open }
  end

  def test_close_raises_nothing_when_client_closed
    assert !@client.open?
    @client.close
  end

end