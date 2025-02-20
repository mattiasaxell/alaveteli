require 'spec_helper'

RSpec.describe AlaveteliPro::ActivityList::RequestSent do
  include Rails.application.routes.url_helpers

  let(:event) { FactoryBot.create(:sent_event) }
  let(:activity) { described_class.new(event) }

  describe '#description' do
    it 'gives an appropriate description' do
      expect(activity.description).
        to eq 'You sent a request "{{info_request_title}}" to ' \
              '{{public_body_name}}.'
    end
  end

  it_behaves_like "an ActivityList::Item with standard #description_urls"

  it_behaves_like "an ActivityList::Item with standard #call_to_action"

  describe '#call_to_action_url' do
    it 'returns the url of the info_request' do
      expect(activity.call_to_action_url).
        to eq request_path(event.info_request)
    end
  end
end
