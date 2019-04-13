class PdfWorker
  include Sidekiq::Worker

  def perform(urls)
    urls.each do |url|
      raptor(url, "test-#{rand(1..20).to_s}")
    end
  end

  def raptor(url, name)
    name.gsub!(/\..*/, '')
    DocRaptor.configure do |config|
      config.username = "YOUR_API_KEY_HERE"
    end

    $docraptor = DocRaptor::DocApi.new
    response = $docraptor.create_doc(
      test: true,
      document_url: url,
      name: name + '.pdf',
      document_type: "pdf",
      )
    save_file(response)
  end
  
  def save_file(pdf_respond)
    File.open("./tmp/docraptor-ruby.pdf", "wb") do |file|
      file.write(pdf_respond)
    end
  end
end
