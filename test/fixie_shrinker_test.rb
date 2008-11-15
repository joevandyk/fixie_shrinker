require 'test/unit'
require 'rubygems'
require 'active_support'
require 'action_controller'
require 'action_pack'
require 'action_view'
require 'lib/fixie_shrinker'
require 'init'

class FixieShrinkerTest < Test::Unit::TestCase

  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::AssetTagHelper
  include FixieShrinker
  FixieShrinker::RAILS_ENV = "development"
  FixieShrinker::RAILS_ROOT = File.dirname(__FILE__) 

  def test_shrink_js
    assert_equal(%q(<script src="/javascripts/compressed_test.js" type="text/javascript"></script>),
                  compress_and_include_javascripts("compressed_test.js", "1.js", "2"))
    expected_result = %q(var foo="You suck!!";var joe="does not suck!";var bob="I rule!";)
    assert_equal expected_result, File.read(FixieShrinker::RAILS_ROOT + "/public/javascripts/compressed_test.js")
  end
  
  def test_shrink_css
    assert_equal(%q(<link href="/stylesheets/compressed_test.css" media="screen" rel="stylesheet" type="text/css" />),
                  compress_and_include_stylesheets("compressed_test.css", "1.css", "2.css?23884848483483"))
    expected_result = %q(body{color:white;}h1{color:white;})
    assert_equal expected_result, File.read(FixieShrinker::RAILS_ROOT + "/public/stylesheets/compressed_test.css")
  end

  def teardown
    `rm -f */*/*/compressed_test*`
    `rm -rf test/tmp`
  end
end
