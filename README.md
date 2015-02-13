# akismet

A Ruby client for the [Akismet API](http://akismet.com/development/api/).

[![Gem Version](https://badge.fury.io/rb/akismet.svg)](http://badge.fury.io/rb/akismet)
[![Build Status](https://travis-ci.org/jonahb/akismet.svg?branch=master)](https://travis-ci.org/jonahb/akismet)

## Getting Started

### Installation

```bash
gem install akismet
```

### Documentation

This README provides an overview of `akismet`. Full documentation is
available at [rubydoc.info](http://www.rubydoc.info/gems/akismet).

### API Key

Sign up at [akismet.com](https://akismet.com/) and retrieve your API
key from your [account page](https://akismet.com/account/).

## Usage

### Basics

Set your API key and app URL (a URL representing your app):

```ruby
Akismet.api_key = '<your API key>'
Akismet.app_url = 'http://example.com'
```

Then check whether a comment is spam ...

```ruby
# request is a Rack::Request
is_spam = Akismet.spam?(request.ip, request.user_agent, text: 'Poppycock!')
```

... file a spam report ...

```ruby
Akismet.spam request.ip, request.user_agent, text: 'I earn $2,000 a week ...'
```

... or flag a false positive ("ham" is not-spam):

```ruby
Akismet.ham request.ip, request.user_agent, text: '"Viagra" derives from the Sanskrit ...'
```

### Accuracy

To maximize the accuracy of the filter, submit as many of the [documented](http://www.rubydoc.info/gems/akismet) parameters as possible. Also submit environment variables related to the comment as a hash in the `env` parameter (Akismet suggests [these variables](http://php.net/manual/en/reserved.variables.server.php)):

```ruby
vars = %w{
  HTTP_ACCEPT
  HTTP_ACCEPT_ENCODING
  # ...
}

params = {
  type: 'comment',
  text: 'A new life awaits you in the Off-World colonies.',
  created_at: DateTime.now,
  author: 'Eldon',
  author_email: 'eldont@aol.com',
  author_url: 'http://geocities.com/eldont',
  post_url: 'http://example.com/posts/1',
  post_modified_at: DateTime.new(2015, 1, 1),
  referrer: request.referrer,
  env: request.env.slice(*vars) # slice courtesy of Active Support
}

is_spam = Akismet.spam?(request.ip, request.user_agent, params)
```
### Blatant Spam

Akismet flags blatant spam that should be deleted without review. This feature is exposed via `Akismet.check`:

```ruby
is_spam, is_blatant = Akismet.check(request.ip, request.user_agent, text: 'Buy everything ... now!')
```

### Reusing Connections

`Akismet.spam?` and friends create a new TCP connection each time you call them. If you have many comments to check or report, use `Akismet.open` to reuse a single connection:

```ruby
Akismet.open do |client|
  for comment in comments
    is_spam = client.spam?(comment.ip, comment.user_agent, text: comment.text)
  end
end
```

### Akismet::Client

In the example above, the object yielded to the block is an `Akismet::Client`. `Akismet::Client` underlies the `Akismet` class methods. Use it on its own to manually open and close connections or override the global API key:

```ruby
begin
  client = Akismet::Client.new('api-key-2', 'http://example2.com')
  client.open
  client.spam request.ip, request.user_agent, text: 'Bank error in your favor!'
ensure
  client.close
end
```

## Tests

1. Set the environment variable AKISMET\_API\_KEY to your API key
2. `rake`

## Contributing

Please submit issues and pull requests to [jonahb/akismet](https://github.com/jonahb/akismet) on GitHub.
