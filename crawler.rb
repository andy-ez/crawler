require 'set'
require 'open-uri'
require 'open_uri_redirections'
require 'net/https'
require 'nokogiri'
require 'json'

class Crawler
  attr_accessor :url, :domain, :visited_pages, :data

  def initialize(url)
    raise ArguementError.new('Invalid URL') unless valid_url?(url)
    @url = URI.parse(url)
    # @url.host = @url.host.start_with?('www.') ? @url.host : 'www.'+@url.host
    @domain = @url.scheme + '://' + @url.host
    @visited_pages = Set.new([@domain])
    @data = []
    get_all_domain_links
    puts 'Crawling complete. Run the #json_data method to view results.'
  end

  def json_data
    puts JSON.pretty_generate(@data)
  end

  private

  def valid_url?(url)
    !!(url =~ /\A#{URI::regexp(['http', 'https'])}\z/)
  end

  def get_all_domain_links(starting_url = @domain)
    page_uris = get_page_uris(starting_url)
    visit_all_page_links(page_uris)
  end

  def parse_links(links)
    ignore_files = %w(.css .js .gz .txt .zip .jpg .png .jpeg .gif .svg)
    uris = links.map { |link| URI.join(@domain, URI.encode(link.strip.gsub(/^[^a-zA-Z0-9\/]+/, ''))) }
    uris.reject! { |uri| ignore_files.any? { |extn| (uri.path || '').end_with?(extn) } }
    uris.each { |uri| uri.fragment = nil }
    uris.each { |uri| uri.query = nil }
    uris.reject { |uri| !valid_url?(uri.to_s) }.uniq!
    uris.select { |uri| (uri.host == @url.host) || (uri.host == 'www.' + @url.host) }
  end

  def get_page_uris(url)
    puts "Running...getting links on #{url}"
    html = Nokogiri.HTML(open(url, allow_redirections: :all))
    get_page_assets(html, url)
    links = html.css('a[href]').map { |a| a['href'] }
    parse_links(links)
  end

  def get_page_assets(html, url)
    data = {
      url: url,
      assets: []
    }
    push_asset_links(html).each { |link| data[:assets] << link }
    @data << data
  end

  def push_asset_links(html, results = [])
    process_asset_links(html.css('script, img').map { |ele| ele['src'] }, results)
    process_asset_links(html.css('link').map { |ele| ele['href'] }, results)
    results
  end

  def process_asset_links(assets, results = [])
    assets.compact.uniq
          .map { |ref| URI.join(@domain, URI.encode(ref)).to_s }
          .each { |file| results << file }
  end

  def visit_all_page_links(uris)
    uris.each do |uri|
      begin
        unless @visited_pages.include?(uri.to_s)
          @visited_pages << uri.to_s
          get_all_domain_links(uri.to_s)
        end
      rescue OpenURI::HTTPError
        puts 'Error- Invalid URI'
      end
    end
  end
end
