require 'spec_helper'

RSpec.describe Admin::LinkHelper do
  describe '#both_links' do
    subject { helper.both_links(record) }

    context 'the record is a known class' do
      let(:record) { FactoryBot.create(:user) }
      it { is_expected.to eq(helper.send(:user_both_links, record)) }
    end

    context 'the record is unsupported' do
      let(:record) { OpenStruct.new }

      it 'raises an NoMethodError' do
        expect { subject }.to raise_error(NoMethodError)
      end
    end

    context 'with an InfoRequest' do
      let(:record) { FactoryBot.create(:info_request) }

      it { is_expected.to include('icon-prominence') }
      it { is_expected.to include(request_path(record)) }
      it { is_expected.to include(admin_request_path(record)) }
    end

    context 'with an OutgoingMessage' do
      let(:record) { FactoryBot.create(:initial_request) }

      it { is_expected.to include('icon-prominence') }
      it { is_expected.to include("#outgoing-#{record.id}") }
      it { is_expected.to include(outgoing_message_path(record)) }
      it { is_expected.to include(edit_admin_outgoing_message_path(record)) }
    end

    context 'with an IncomingMessage' do
      let(:record) { FactoryBot.create(:incoming_message) }

      it { is_expected.to include('icon-prominence') }
      it { is_expected.to include("#incoming-#{record.id}") }
      it { is_expected.to include(incoming_message_path(record)) }
      it { is_expected.to include(edit_admin_incoming_message_path(record)) }
    end

    context 'with a FoiAttachment' do
      let(:info_request) do
        FactoryBot.create(:info_request, :with_plain_incoming)
      end
      let(:incoming_message) { info_request.incoming_messages.first }
      let!(:record) { incoming_message.foi_attachments.first }

      it { is_expected.to include('icon-prominence') }
      it { is_expected.to include(record.filename) }
      it { is_expected.to include(foi_attachment_path(record)) }
      it { is_expected.to include(edit_admin_foi_attachment_path(record)) }
    end

    context 'with an InfoRequestBatch' do
      let(:record) { FactoryBot.create(:info_request_batch) }

      it { is_expected.to include('icon-prominence') }
      it { is_expected.to include(record.title) }
      it { is_expected.to include(info_request_batch_path(record)) }
      it { is_expected.to include(admin_info_request_batch_path(record)) }
    end

    context 'with a PublicBody' do
      let(:record) { FactoryBot.create(:public_body) }

      it { is_expected.to include('icon-eye-open') }
      it { is_expected.to include(public_body_path(record)) }
      it { is_expected.to include(admin_body_path(record)) }
    end

    context 'with a User' do
      let(:record) { FactoryBot.create(:user) }

      it { is_expected.to include('icon-prominence') }
      it { is_expected.to include(user_path(record)) }
      it { is_expected.to include(admin_user_path(record)) }
    end

    context 'with a Comment' do
      let(:record) { FactoryBot.create(:comment) }

      it { is_expected.to include('icon-prominence') }
      it { is_expected.to include(comment_path(record)) }
      it { is_expected.to include(edit_admin_comment_path(record)) }
    end

    context 'with a Blog Post' do
      let(:record) { FactoryBot.create(:blog_post) }

      it { is_expected.to include('icon-eye-open') }
      it { is_expected.to include(record.url) }
      it { is_expected.to include(edit_admin_blog_post_path(record)) }
    end

    context 'with a TrackThing' do
      context 'tracking a search' do
        let(:record) { FactoryBot.create(:search_track) }

        it { is_expected.to include('icon-eye-open') }
        it { is_expected.to include("#{record.id}:") }
        it { is_expected.to include(search_general_path(record.track_query)) }
      end

      context 'tracking a trackable record' do
        let(:record) { FactoryBot.create(:request_update_track) }
        let(:url_title) { record.info_request.url_title }

        it { is_expected.to include('icon-eye-open') }
        it { is_expected.to include("#{record.id}:") }

        it do
          is_expected.to include(search_general_path("request:#{url_title}"))
        end
      end
    end

    context 'with a Citation' do
      let(:record) { FactoryBot.create(:citation) }

      it { is_expected.to include('icon-eye-open') }
      it { is_expected.to include(record.source_url) }
      it { is_expected.to include(edit_admin_citation_path(record)) }
    end
  end
end
