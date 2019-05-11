require 'rails_helper'

RSpec.describe HomesController, type: :controller do
  login_admin

  describe "GET #pdf_metadata" do
    before do
      params = {urls: ["http://docraptor.com/examples/invoice.html", "http://docraptor.com/"], urls1: ["http://docraptor.com/samples"]}
      get :pdf_metadata, params: params, as: :json
    end

    it "response JSON body containing expected attributes" do
      expect { JSON.parse(response.body) }.not_to raise_exception
      hash_body = JSON.parse(response.body)
      # "2 groups urls ()urls and urls1) in request"
      expect(hash_body.count).to eql(2)
      # "Two links inside one group"
      expect(hash_body[0][" 1 "].count).to eql(2)
      # "Checking correct format JSON response"
      expect(hash_body[0][" 1 "][0].keys).to match_array(["url", "pdf_version", "info", "metadata", "page_count"])
      expect(hash_body[0][" 1 "][0]).to match(
        "url" => 1.5,
        "pdf_version" => 1.5,
        "info" => {
          "Producer" => "Prince 12.4 (www.princexml.com)",
          "Author" => "Expected Behavior",
          "Title" => "HTML to PDF API for Ruby, PHP, Node, Java and more"
       },
        "metadata" => nil,
        "page_count" => 4
       )
    end
  end
end