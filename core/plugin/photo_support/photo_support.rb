# coding: utf-8
require 'nokogiri'
require 'httpclient'
require 'totoridipjp'

module Plugin::PhotoSupport
  INSTAGRAM_PATTERN = %r{\Ahttps?://(?:instagr\.am|(?:www\.)?instagram\.com)/p/([a-zA-Z0-9_\-]+)/}

  class << self
    # Twitter cardsのURLを画像のURLに置き換える。
    # HTMLを頻繁にリクエストしないように、このメソッドを通すことでメモ化している。
    # ==== Args
    # [display_url] http://d250g2.com/
    # ==== Return
    # String 画像URL(http://d250g2.com/d250g2.jpg)
    def d250g2(display_url)
      connection = HTTPClient.new
      page = connection.get_content(display_url)
      unless page.empty?
        doc = Nokogiri::HTML(page)
        doc.css('meta[name="twitter:image:src"]').first.attribute('content') end end
    memoize :d250g2
  end
end

Plugin.create :photo_support do
  # twitpic
  defimageopener('twitpic', %r<^http://twitpic\.com/[a-zA-Z0-9]+>) do |display_url|
    connection = HTTPClient.new
    page = connection.get_content(display_url)
    next nil if page.empty?
    doc = Nokogiri::HTML(page)
    result = doc.css('img').lazy.find_all{ |dom|
      %r<https?://.*?\.cloudfront\.net/photos/(?:large|full)/.*> =~ dom.attribute('src')
    }.first
    open(result.attribute('src'))
  end

  # twipple photo
  defimageopener('twipple photo', %r<^http://p\.twipple\.jp/[a-zA-Z0-9]+>) do |display_url|
    connection = HTTPClient.new
    page = connection.get_content(display_url)
    next nil if page.empty?
    doc = Nokogiri::HTML(page)
    result = doc.css('#post_image').first
    open(result.attribute('src'))
  end

  # moby picture
  defimageopener('moby picture', %r<^http://moby.to/[a-zA-Z0-9]+>) do |display_url|
    connection = HTTPClient.new
    page = connection.get_content(display_url)
    next nil if page.empty?
    doc = Nokogiri::HTML(page)
    result = doc.css('#main_picture').first
    open(result.attribute('src'))
  end

  # gyazo
  defimageopener('gyazo', %r<\Ahttps?://gyazo.com/[a-zA-Z0-9]+>) do |display_url|
    connection = HTTPClient.new
    page = connection.get_content(display_url)
    next nil if page.empty?
    doc = Nokogiri::HTML(page)
    result = doc.css('.image').first
    open(result.attribute('src'))
  end

  # 携帯百景
  defimageopener('携帯百景', %r<^http://movapic.com/(?:[a-zA-Z0-9]+/pic/\d+|pic/[a-zA-Z0-9]+)>) do |display_url|
    connection = HTTPClient.new
    page = connection.get_content(display_url)
    next nil if page.empty?
    doc = Nokogiri::HTML(page)
    result = doc.css('.image').lazy.find_all{ |dom|
      %r<^http://image\.movapic\.com/pic/> =~ dom.attribute('src')
    }.first
    open(result.attribute('src'))
  end

  # piapro
  defimageopener('piapro', %r<^http://piapro.jp/t/[a-zA-Z0-9]+>) do |display_url|
    connection = HTTPClient.new
    page = connection.get_content(display_url)
    next nil if page.empty?
    doc = Nokogiri::HTML(page)
    dom = doc.css('.illust-whole img').first
    url = dom && dom.attribute('src')
    if url
      open(url) end
  end

  # img.ly
  defimageopener('img.ly', %r<^http://img\.ly/[a-zA-Z0-9_]+>) do |display_url|
    connection = HTTPClient.new
    page = connection.get_content(display_url)
    next nil if page.empty?
    doc = Nokogiri::HTML(page)
    result = doc.css('#the-image').first
    open(result.attribute('src'))
  end

  # twitgoo
  defimageopener('twitgoo', %r<^http://twitgoo\.com/[a-zA-Z0-9]+>) do |display_url|
    open(display_url)
  end

  # jigokuno.com
  defimageopener('jigokuno.com', %r<^http://jigokuno\.com/\?eid=\d+>) do |display_url|
    connection = HTTPClient.new
    page = connection.get_content(display_url)
    next nil if page.empty?
    doc = Nokogiri::HTML(page)
    open(doc.css('img.pict').first.attribute('src'))
  end

  # はてなフォトライフ
  defimageopener('はてなフォトライフ', %r<^http://f\.hatena\.ne\.jp/[-\w]+/\d{9,}>) do |display_url|
    connection = HTTPClient.new
    page = connection.get_content(display_url)
    next nil if page.empty?
    doc = Nokogiri::HTML(page)
    result = doc.css('img.foto').first
    open(result.attribute('src'))
  end

  # imgur
  defimageopener('imgur', %r<http://imgur\.com(/gallery)?/\w+>) do |display_url|
    connection = HTTPClient.new
    page = connection.get_content(display_url)
    next nil if page.empty?
    doc = Nokogiri::HTML(page)
    result = doc.css('img').lazy.find_all{ |dom|
      'image_src' == dom.attribute('rel')
    }.first
    open(result.attribute('href'))
  end

  # Fotolog
  defimageopener('Fotolog', %r<http://(?:www\.)fotolog\.com/\w+/\d+/?>) do |display_url|
    connection = HTTPClient.new
    page = connection.get_content(display_url)
    next nil if page.empty?
    doc = Nokogiri::HTML(page)
    result = doc.css('meta').lazy.find_all{ |dom|
      'og:image' == dom.attribute('property').to_s
    }.first
    open(result.attribute('content'))
  end

  # フォト蔵
  defimageopener('フォト蔵', %r<^http://photozou\.jp/photo/show/\d+/\d+>) do |display_url|
    connection = HTTPClient.new
    page = connection.get_content(display_url)
    next nil if page.empty?
    doc = Nokogiri::HTML(page)
    open(doc.css('img[itemprop="image"]').first.attribute('src'))
  end

  # instagram
  defimageopener('instagram', Plugin::PhotoSupport::INSTAGRAM_PATTERN) do |display_url|
    notice display_url
    connection = HTTPClient.new
    page = connection.get_content(display_url)
    next nil if page.empty?
    doc = Nokogiri::HTML(page)
    result = doc.xpath("//meta[@property='og:image']/@content").first
    open(result)
  end

  # d250g2
  defimageopener('d250g2', %r#\Ahttps?://(?:[\w\-]+\.)?d250g2\.com/?\Z#) do |display_url|
    img = Plugin::PhotoSupport.d250g2(display_url)
    open(img) if img
  end

  # d250g2(Twitpicが消えたとき用)
  defimageopener('d250g2(Twitpicが消えたとき用)', %r#\Ahttp://twitpic\.com/d250g2\Z#) do
    open('http://d250g2.com/d250g2.jpg')
  end

  # totori.dip.jp
  defimageopener('totori.dip.jp', %r#\Ahttp://totori\.dip\.jp/?\Z#) do |display_url|
    iwashi = Totoridipjp.イワシがいっぱいだあ…ちょっとだけもらっていこうかな
    if iwashi.url
      open(iwashi.url) end
  end

  # 600eur.gochiusa.net
  defimageopener('600eur.gochiusa.net', %r#\Ahttp://600eur\.gochiusa\.net/?\Z#) do |display_url|
    img = Plugin::PhotoSupport.d250g2(display_url)
    open(img) if img
  end

  # yfrog
  defimageopener('yfrog', %r#\Ahttps?://yfrog\.com/es3bcstj\Z#) do
    img = Plugin::PhotoSupport.d250g2('http://router-cake.d250g2.com/')
    open(img) if img
  end

  defimageopener('いらすとや', %r<https?://(?:www.)?irasutoya\.com/\d{4}/\d{2}/.+\.html>) do |display_url|
    img = Plugin::PhotoSupport.d250g2(display_url)
    open(img) if img
  end
  
  # vine
  defimageopener('vine', %r<\Ahttps?://vine\.co/v/[a-zA-Z0-9]+>) do |display_url|
    connection = HTTPClient.new
    page = connection.get_content(display_url)
    next nil if page.empty?
    doc = Nokogiri::HTML(page)
    result = doc.css('meta[property="twitter:image:src"]')
    open(result.attribute('content').value)
  end
end
