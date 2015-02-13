require 'test_helper'

class AkismetTest < Test

  def setup
    Akismet.api_key = API_KEY
    Akismet.app_url = 'http://example.com'
  end

  [:spam?, :check, :spam, :ham].each do |method|
    define_method("test_#{method}_succeeds") do
      Akismet.send method, 'ip', 'ua'
    end
  end

  def test_check_raises_if_api_key_not_set
    Akismet.api_key = nil
    assert_raises(RuntimeError) do
      Akismet.check 'ip', 'ua'
    end
  end

  def test_check_raises_if_app_url_not_set
    Akismet.app_url = nil
    assert_raises(RuntimeError) do
      Akismet.check 'ip', 'ua'
    end
  end

  def test_open_succeeds
    Akismet.open do |client|
      client.check 'ip', 'ua'
    end
  end

  def test_open_raises_without_block
    assert_raises(RuntimeError) do
      Akismet.open
    end
  end

end
