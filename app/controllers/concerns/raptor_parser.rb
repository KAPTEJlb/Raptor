module RaptorParser
  extend ActiveSupport::Concern

  def raptor_api(url, name)
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
    save_file(response, name)
  end

  def save_file(pdf_respond, name)
    File.open("./tmp/pdfs/#{name}.pdf", "wb") do |file|
      file.write(pdf_respond)
    end
  end
end