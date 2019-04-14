class PdfWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker

  def expiration
    @expiration ||= 60 * 60 * 24 * 30 # 30 days
  end

  def perform(urls)
    total 100
    job = SidekiqStatus.new(job_id: self.jid)
    job.save
    procentege = 100 / urls.count
    urls.each_with_index do |url, index|
      raptor(url, "test-#{rand(1..20).to_s}")
      status = job_status(index, urls, procentege)
      at status[0], status[1]
      job.update(progress: status[0].to_i, message: status[1])
      SidekiqStatus.new
    end
  end

  def job_status(index, urls, procentege)
    if index == urls.size - 1
      return  [100, "Done"]
    else
      return [(index + 1) * procentege, "Almost done"]
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
    save_file(response, name)
  end

  def save_file(pdf_respond, name)
    File.open("./tmp/#{name}.pdf", "wb") do |file|
      file.write(pdf_respond)
    end
  end
end