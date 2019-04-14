class PdfWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker
  include Firebase

  def expiration
    @expiration ||= 60 * 60 * 24 * 30 # 30 days
  end

  def perform(urls)
    sleep(3)
    initialize_firebase
    total 100
    job = SidekiqStatus.find_by(job_id: self.jid)
    procentege = 100 / urls.count
    urls.each_with_index do |url, index|
      begin
        raptor(url, url.gsub(/\W/, ''))
        status = job_status(index, urls, procentege)
        at status[0], status[1]
        firebase(self.jid, status[0].to_i, status[1])
        job.update(progress: status[0].to_i, message: status[1])
      rescue
        job.sidekiq_errors.new(error_messages: "Unfortunately, we can't download PDF from this website #{url}").save
        next
      end
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

  def firebase(prs_id, status, message)
    @firebase.update("SidekiqJob/#{prs_id}/", { process_id: prs_id, status: status, message: message })
  end

  def initialize_firebase
    base_uri = 'https://raptor-fc7b8.firebaseio.com'

    @firebase = Firebase::Client.new(base_uri)
  end
end