Akismet
=======

A Ruby client for the Akismet API.

Instantiate an `Akismet::Client` with your API key and home page URL. Then
call `verify_key`, `check_comment`, `submit_ham`, or `submit_spam`.

Use `Akismet::Client.open` or `Akismet::Client#open` to submit multiple
requests over a single TCP connection.

See lib/akismet/client.rb for more documentation or generate docs with YARD. 

Verify an API key
-----------------

    Akismet::Client.new( 'apikey123', 'http://jonahb.com' ).verify_key


Check whether a comment is spam
-------------------------------

    client = Akismet::Client.new( 'apikey123',
      'http://jonahb.com',
      :app_name => 'jonahb.com',
      :app_version => '1.0' )

    # assumes variables comment, post_url, request (a racklike HTTP request)
    spam = client.comment_check( request.remote_ip,
      request.user_agent,
      :content_type => 'comment',
      :referrer => request.headers[ 'HTTP_REFERER' ],
      :permalink => post_url, 
      :comment_author => comment.author,
      :comment_author_email => comment.author_email,
      :comment_content => comment.body )

    if spam
      # ...
    end 

Submit a batch of checks using a single TCP connection
------------------------------------------------------

    client = Akismet::Client.new( 'apikey123',
      'http://jonahb.com',
      :app_name => 'jonahb.com',
      :app_version => '1.0' )

    begin
      client.open
      comments.each do |comment|
        client.comment_check( ... )  # see example above
      end
    ensure
      client.close
    end

    # ... or ...

    Akismet::Client.open( 'apikey123',
      'http://jonahb.com',
      :app_name => 'jonahb.com',
      :app_version => '1.0' ) do |client|
      comments.each do |comment|
        client.comment_check( ... )  # see example above
      end
    end
