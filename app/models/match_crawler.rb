class MatchCrawler
  def request_param(page)
    path = '/a/block_competition_matches?'
    callback_params = {
      page: page.to_s,
      round_id: 17950.to_s,
      outgroup: "",
      view: 2
    }
    params = {
      block_id: "page_competition_1_block_competition_matches_7",
      callback_params: callback_params.to_json,
      action: "changePage",
      params: { page: (page+1).to_s }.to_json
    }

    path + params.to_query
  end

  def crawl(page = -4)
    conn = Faraday.new(url: 'http://www.soccerway.com/') do |c|
      c.use Faraday::Request::UrlEncoded
      c.use Faraday::Response::Logger
      c.use Faraday::Adapter::NetHttp
    end

    response = conn.get request_param(page)
    json = JSON.parse response.body

    result = {}

    for i in -4..0 do
      html = Nokogiri.HTML json["commands"][0]["parameters"]["content"]
      result["page_#{i}"] = process_html(html)
    end

    result
  end

  def process_html(html)
    results = []
    html.css('table.matches > tbody > tr').each do |tr|
      timestamp = tr['data-timestamp'].to_i
      break if (timestamp > Time.now.to_i)

      time = Time.at timestamp
      team_a = tr.css('td.team-a > a').first[:title]
      team_b = tr.css('td.team-b > a').first[:title]
      score = tr.css('td.score > a').first.text
      match = {
        time: time,
        team_a: team_a,
        team_b: team_b,
        score: score
      }
      results << match
    end
    results
  end
end