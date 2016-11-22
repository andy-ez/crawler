require 'minitest/autorun'
require 'minitest/reporters'
require 'fakeweb'
Minitest::Reporters.use!

require_relative '../crawler'

class CrawlerTest < MiniTest::Test

  def setup
    FakeWeb.allow_net_connect = false
    FakeWeb.register_uri(:get, "http://single-example.com", :body => "test_data/single_page.html")
    FakeWeb.register_uri(:get, "http://example.com/single", :body => "test_data/single_page.html")
    FakeWeb.register_uri(:get, "http://example.com", :body => "test_data/links_page.html")
    FakeWeb.register_uri(:get, "http://example.com/docs/nested", :body => "test_data/docs/nested_page.html")
    @crawler = Crawler.new('http://example.com/links')
    @crawler1 = Crawler.new('http://single-example.com')
  end


  def test_single_page_with_no_links

    # test path is ignored in url passed in
    assert_equal('http://single-example.com', @crawler1.domain)
    assert_equal(1, @crawler1.data.size)
    assert_equal('http://single-example.com', @crawler1.data[0][:url])
    assert_includes(@crawler1.data[0][:assets], 'http://single-example.com/test.css')
    assert_includes(@crawler1.data[0][:assets], 'http://single-example.com/test.js')
    assert_equal(2, @crawler1.data[0][:assets].size)
  end

  def test_url_traversal_with_assets_included
    urls = @crawler.data.map { |hash| hash[:url] }
    
    assert_includes(urls, 'http://example.com')
    assert_includes(urls, 'http://example.com/single')
    assert_includes(urls, 'http://example.com/docs/nested')
    assert_equal(3, @crawler.data.size) # tested link to imae was excluded
  end

  def test_correct_assets
    assets = @crawler.data.map { |hash| hash[:assets] }.flatten

    assert_includes(assets, 'http://example.com/links_test.css')
    assert_includes(assets, 'http://example.com/links_test.js')
    assert_includes(assets, 'http://example.com/images/apple.gif')
    assert_includes(assets, 'http://example.com/nested_test.css')
    assert_includes(assets, 'http://example.com/nested_test.js')
    assert_includes(assets, 'http://example.com/apples.jpeg')
    assert_equal(8, assets.size)
  end

end