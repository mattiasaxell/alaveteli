# == Schema Information
# Schema version: 20230717201410
#
# Table name: foi_attachments
#
#  id                    :integer          not null, primary key
#  content_type          :text
#  filename              :text
#  charset               :text
#  display_size          :text
#  url_part_number       :integer
#  within_rfc822_subject :text
#  incoming_message_id   :integer
#  hexdigest             :string(32)
#  created_at            :datetime
#  updated_at            :datetime
#  prominence            :string           default("normal")
#  prominence_reason     :text
#  masked_at             :datetime
#

require 'spec_helper'
require 'models/concerns/message_prominence'

RSpec.describe FoiAttachment do
  it_behaves_like 'concerns/message_prominence', :body_text

  describe '.binary' do
    subject { described_class.binary }

    before do
      FactoryBot.create(:body_text)
      FactoryBot.create(:html_attachment)
    end

    let(:binary_attachments) do
      [FactoryBot.create(:pdf_attachment),
       FactoryBot.create(:rtf_attachment),
       FactoryBot.create(:jpeg_attachment),
       FactoryBot.create(:unknown_attachment)]
    end

    it { is_expected.to match_array(binary_attachments) }
  end

  describe '.cached_urls' do
    it 'includes the correct paths' do
      att = FactoryBot.create(:jpeg_attachment)
      im = FactoryBot.create(:plain_incoming_message)
      att.incoming_message = im
      request_path = "/request/" + att.info_request.url_title
      expect(att.cached_urls).to eq([request_path])
    end
  end

  describe '#body=' do
    it "sets the body" do
      attachment = FoiAttachment.new
      attachment.body = "baz"
      expect(attachment.body).to eq("baz")
    end

    it "sets the size" do
      attachment = FoiAttachment.new
      attachment.body = "baz"
      expect(attachment.body).to eq("baz")
      expect(attachment.display_size).to eq("0K")
    end

    it "reparses the body if it disappears" do
      load_raw_emails_data
      im = incoming_messages(:useless_incoming_message)
      im.extract_attachments!
      main = im.get_main_body_text_part
      orig_body = main.body
      main.delete_cached_file!
      expect {
        im.get_main_body_text_part.body
      }.not_to raise_error
      main.delete_cached_file!
      main = im.get_main_body_text_part
      expect(main.body).to eq(orig_body)
    end

    it 'can parse raw email and read attachment inside DB transaction' do
      im = FactoryBot.create(:plain_incoming_message)
      FoiAttachment.transaction do
        expect { im.get_text_for_indexing_full }.to_not raise_error
        main_part = im.get_main_body_text_part
        expect(main_part.body).to match(/That's so totally a rubbish question/)
      end
    end

    it 'does not update hexdigest if already present' do
      attachment = FoiAttachment.new(hexdigest: 'ABC')
      expect { attachment.body = 'foo' }.to_not change { attachment.hexdigest }
    end

    it 'allow calls to #body to be made before save' do
      attachment = FactoryBot.build(:foi_attachment, :unmasked)
      blob = attachment.file.blob

      expect {
        attachment.body
        attachment.save!
      }.to change {
        ActiveStorage::Blob.services.fetch(blob.service_name).exist?(blob.key)
      }.from(false).to(true)
    end
  end

  describe '#body' do
    context 'when masked' do
      let(:foi_attachment) { FactoryBot.create(:body_text) }

      it 'returns a binary encoded string when newly created' do
        expect(foi_attachment.body.encoding.to_s).to eq('ASCII-8BIT')
      end

      it 'returns a binary encoded string when saved' do
        foi_attachment_2 = FoiAttachment.find(foi_attachment.id)
        expect(foi_attachment_2.body.encoding.to_s).to eq('ASCII-8BIT')
      end
    end

    context 'when masked but stored attachment is missing' do
      let(:foi_attachment) { FactoryBot.create(:body_text) }

      before do
        allow(foi_attachment.file).
          to receive(:download).and_raise(ActiveStorage::FileNotFoundError)
      end

      it 'calls the FoiAttachmentMaskJob now and return the masked body' do
        expect(FoiAttachmentMaskJob).to receive(:perform_now).
          with(foi_attachment).
          and_invoke(-> (_) {
            # mock the job
            foi_attachment.update(body: 'maskedbody', masked_at: Time.zone.now)
          })

        expect(foi_attachment.body).to eq('maskedbody')
      end
    end

    context 'when unmasked and original attachment can be found' do
      let(:incoming_message) do
        FactoryBot.create(:incoming_message, foi_attachments_factories: [
          [:body_text, :unmasked]
        ])
      end
      let(:foi_attachment) { incoming_message.foi_attachments.last }

      it 'calls the FoiAttachmentMaskJob now and return the masked body' do
        expect(FoiAttachmentMaskJob).to receive(:perform_now).
          with(foi_attachment).
          and_invoke(-> (_) {
            # mock the job
            foi_attachment.update(body: 'maskedbody', masked_at: Time.zone.now)
          })

        expect(foi_attachment.body).to eq('maskedbody')
      end
    end

    context 'when unmasked and original attachment can not be found' do
      let(:incoming_message) do
        FactoryBot.create(:incoming_message, foi_attachments_factories: [
          [:body_text, :unmasked]
        ])
      end
      let(:foi_attachment) { incoming_message.foi_attachments.last }

      before do
        foi_attachment.update(hexdigest: '123')

        expect(FoiAttachmentMaskJob).to receive(:perform_now).
          with(foi_attachment).
          and_invoke(-> (_) {
            # mock the job
            incoming_message.parse_raw_email!(true)
          })
      end

      it 'returns load_attachment_from_incoming_message.body' do
        allow(foi_attachment).to(
          receive(:load_attachment_from_incoming_message).and_return(
            double(body: 'thisisthenewtext')
          )
        )
        expect(foi_attachment.body).to eq('thisisthenewtext')
      end

      it 'raises MissingAttachment exception if attachment still can not be found' do
        allow(foi_attachment).to(
          receive(:load_attachment_from_incoming_message).and_return(nil)
        )
        expect { foi_attachment.body }.to raise_error(
          FoiAttachment::MissingAttachment
        )
      end
    end

    context 'when attachment has been destroy' do
      let(:foi_attachment) { FactoryBot.create(:foi_attachment) }

      before { foi_attachment.destroy }

      it 'returns load_attachment_from_incoming_message.body' do
        allow(foi_attachment).to(
          receive(:load_attachment_from_incoming_message).and_return(
            double(body: 'thisisthenewtext')
          )
        )
        expect(foi_attachment.body).to eq('thisisthenewtext')
      end
    end
  end

  describe '#body_as_text' do
    it 'has a valid UTF-8 string when newly created' do
      foi_attachment = FactoryBot.create(:body_text)
      expect(foi_attachment.body_as_text.string.encoding.to_s).to eq('UTF-8')
      expect(foi_attachment.body_as_text.string.valid_encoding?).to be true
    end

    it 'has a valid UTF-8 string when saved' do
      foi_attachment = FactoryBot.create(:body_text)
      foi_attachment = FoiAttachment.find(foi_attachment.id)
      expect(foi_attachment.body_as_text.string.encoding.to_s).to eq('UTF-8')
      expect(foi_attachment.body_as_text.string.valid_encoding?).to be true
    end

    it 'has a true scrubbed? value if the body has been coerced to valid UTF-8' do
      foi_attachment = FactoryBot.create(:body_text)
      foi_attachment.body = "\x0FX\x1C\x8F\xA4\xCF\xF6\x8C\x9D\xA7\x06\xD9\xF7\x90lo"
      expect(foi_attachment.body_as_text.scrubbed?).to be true
    end

    it 'has a false scrubbed? value if the body has not been coerced to valid UTF-8' do
      foi_attachment = FactoryBot.create(:body_text)
      foi_attachment.body = "κόσμε"
      expect(foi_attachment.body_as_text.scrubbed?).to be false
    end
  end

  describe '#default_body' do
    it 'returns valid UTF-8 for a text attachment' do
      foi_attachment = FactoryBot.create(:body_text)
      expect(foi_attachment.default_body.encoding.to_s).to eq('UTF-8')
      expect(foi_attachment.default_body.valid_encoding?).to be true
    end

    it 'returns binary for a PDF attachment' do
      foi_attachment = FactoryBot.create(:pdf_attachment)
      expect(foi_attachment.default_body.encoding.to_s).to eq('ASCII-8BIT')
    end
  end

  describe '#unmasked_body' do
    let(:foi_attachment) { FactoryBot.create(:body_text) }
    subject(:unmasked_body) { foi_attachment.unmasked_body }

    before do
      allow(foi_attachment).to receive(:raw_email).
        and_return(double(mail: Mail.new))
    end

    context 'when mail handler finds original attachment by hexdigest' do
      before do
        allow(MailHandler).to receive(:attachment_body_for_hexdigest).
          and_return('hereistheunmaskedtext')
      end

      it 'returns the attachment body from the raw email' do
        is_expected.to eq('hereistheunmaskedtext')
      end
    end

    context 'when able to find original attachment through other means' do
      before do
        allow(MailHandler).to receive(:attachment_body_for_hexdigest).
          and_raise(MailHandler::MismatchedAttachmentHexdigest)

        allow(MailHandler).to receive(
          :attempt_to_find_original_attachment_attributes
        ).and_return(hexdigest: 'ABC', body: 'hereistheunmaskedtext')
      end

      it 'updates the hexdigest' do
        expect { unmasked_body }.to change { foi_attachment.hexdigest }.
          to('ABC')
      end

      it 'returns the attachment body from the raw email' do
        is_expected.to eq('hereistheunmaskedtext')
      end
    end

    context 'when unable to find original attachment in storage' do
      before do
        allow(foi_attachment.file).
          to receive(:download).and_raise(ActiveStorage::FileNotFoundError)
      end

      it 'raises missing attachment exception' do
        expect { unmasked_body }.to raise_error(
          FoiAttachment::MissingAttachment,
          "attachment missing from storage (ID=#{foi_attachment.id})"
        )
      end
    end

    context 'when unable to find original attachment through other means' do
      before do
        allow(MailHandler).to receive(:attachment_body_for_hexdigest).
          and_raise(MailHandler::MismatchedAttachmentHexdigest)

        allow(MailHandler).to receive(
          :attempt_to_find_original_attachment_attributes
        ).and_return(nil)
      end

      it 'raises missing attachment exception' do
        expect { unmasked_body }.to raise_error(
          FoiAttachment::MissingAttachment,
          "attachment missing in raw email (ID=#{foi_attachment.id})"
        )
      end
    end
  end

  describe 'masked?' do
    let(:foi_attachment) do
      FoiAttachment.new(body: 'foo', masked_at: Time.zone.now)
    end

    subject { foi_attachment.masked? }

    it { is_expected.to eq(true) }

    context 'without file attached' do
      let(:foi_attachment) { FoiAttachment.new(masked_at: Time.zone.now) }
      it { is_expected.to eq(false) }
    end

    context 'without masked_at' do
      let(:foi_attachment) { FoiAttachment.new(body: 'foo') }
      it { is_expected.to eq(false) }
    end

    context 'when masked_at is in the future' do
      let(:foi_attachment) do
        FoiAttachment.new(body: 'foo', masked_at: Time.zone.now + 1.day)
      end

      it { is_expected.to eq(false) }
    end
  end

  describe '#main_body_part?' do
    subject { attachment.main_body_part? }

    let(:message) { FactoryBot.build(:incoming_message, :with_pdf_attachment) }

    context 'when the attachment is the main body' do
      let(:attachment) { message.get_main_body_text_part }
      it { is_expected.to eq(true) }
    end

    context 'when the attachment is not the main body' do
      let(:attachment) { message.get_attachments_for_display.first }
      it { is_expected.to eq(false) }
    end
  end

  describe '#filename=' do
    it 'strips null bytes' do
      attachment = FactoryBot.build(:pdf_attachment)
      attachment.filename = "Tender Loving Care Trust (Europe).pdf\u0000"
      expect(attachment.filename).to eq('Tender Loving Care Trust (Europe).pdf')
    end
  end

  describe '#ensure_filename!' do
    it 'should create a filename for an instance with a blank filename' do
      attachment = FoiAttachment.new
      attachment.filename = ''
      attachment.ensure_filename!
      expect(attachment.filename).to eq('attachment.bin')
    end
  end

  describe '#has_body_as_html?' do
    it 'should be true for a pdf attachment' do
      expect(FactoryBot.build(:pdf_attachment).has_body_as_html?).to be true
    end

    it 'should be false for an html attachment' do
      expect(FactoryBot.build(:html_attachment).has_body_as_html?).to be false
    end
  end

  describe '#name_of_content_type' do
    subject { foi_attachment.name_of_content_type }

    before do
      stub = { 'content/named' => 'Named content' }
      stub_const("#{described_class}::CONTENT_TYPE_NAMES", stub)
    end

    let(:foi_attachment) do
      FactoryBot.build(:foi_attachment, content_type: content_type)
    end

    context 'when the content_type has a name' do
      let(:content_type) { 'content/named' }
      it { is_expected.to eq('Named content') }
    end

    context 'when the content_type has no name' do
      let(:content_type) { 'content/unnamed' }
      it { is_expected.to be_nil }
    end
  end

  describe '#expire' do
    let(:incoming_message) { FactoryBot.create(:incoming_message) }
    let(:foi_attachment) { incoming_message.foi_attachments.first }

    it 'delegates to info_request' do
      expect(foi_attachment.info_request).to receive(:expire)
      foi_attachment.expire
    end
  end

  describe '#log_event' do
    let(:incoming_message) { FactoryBot.create(:incoming_message) }
    let(:foi_attachment) { incoming_message.foi_attachments.first }

    it 'delegates to info_request' do
      expect(foi_attachment.info_request).to receive(:log_event).with('edit')
      foi_attachment.log_event('edit')
    end
  end

  describe '#update_and_log_event' do
    let(:incoming_message) { FactoryBot.create(:incoming_message) }
    let(:info_request) { incoming_message.info_request }
    let(:foi_attachment) { incoming_message.foi_attachments.first }

    def last_event
      info_request.info_request_events.last
    end

    it 'updates and logs edit_attachment event' do
      expect do
        foi_attachment.update_and_log_event(prominence: 'hidden')
      end.to change { last_event }

      expect(last_event.event_type).to eq('edit_attachment')
    end

    it 'logs prominence and reason changes' do
      foi_attachment.update_and_log_event(
        prominence: 'hidden', prominence_reason: 'just because'
      )
      expect(last_event.params[:old_prominence]).to eq('normal')
      expect(last_event.params[:prominence]).to eq('hidden')
      expect(last_event.params[:old_prominence_reason]).to be_nil
      expect(last_event.params[:prominence_reason]).to eq('just because')
    end

    it 'logs additional event data' do
      foi_attachment.update_and_log_event(
        prominence: 'hidden', event: { editor: 'me' }
      )
      expect(last_event.params[:editor]).to eq('me')
    end

    it 'does not log event if update fails' do
      expect do
        foi_attachment.update_and_log_event(prominence: nil)
      end.to_not change { last_event }
    end
  end
end
