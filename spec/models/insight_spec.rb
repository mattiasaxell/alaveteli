# == Schema Information
# Schema version: 20241024140606
#
# Table name: insights
#
#  id              :bigint           not null, primary key
#  info_request_id :bigint
#  model           :string
#  template        :text
#  output          :jsonb
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
require 'spec_helper'

RSpec.describe Insight, type: :model do
  describe 'associations' do
    it 'belongs to info_request' do
      insight = FactoryBot.build(:insight)
      expect(insight.info_request).to be_a(InfoRequest)
    end

    it 'has many outgoing_messages through info_request' do
      insight = FactoryBot.build(:insight)
      expect(insight.outgoing_messages).to all(be_a(OutgoingMessage))
    end
  end

  describe 'validations' do
    it 'requires info_request' do
      insight = FactoryBot.build(:insight)
      insight.info_request = nil
      expect(insight).not_to be_valid
    end

    it 'requires model' do
      insight = FactoryBot.build(:insight)
      insight.model = nil
      expect(insight).not_to be_valid
    end

    it 'requires template' do
      insight = FactoryBot.build(:insight)
      insight.template = nil
      expect(insight).not_to be_valid
    end
  end

  describe 'callbacks' do
    it 'queues InsightJob after create' do
      expect(InsightJob).to receive(:perform_later)
      FactoryBot.create(:insight)
    end
  end

  describe '.client' do
    it 'returns an Ollama instance' do
      expect(described_class.client).to be_a(Ollama::Controllers::Client)
    end
  end

  describe '.models' do
    let(:mock_client) { instance_double(Ollama::Controllers::Client) }
    let(:mock_tags) do
      [{ 'models' => [{ 'model' => 'model1' }, { 'model' => 'model2' }] }]
    end

    before do
      allow(described_class).to receive(:client).and_return(mock_client)
      allow(mock_client).to receive(:tags).and_return(mock_tags)
    end

    it 'returns sorted list of models' do
      expect(described_class.models).to eq(%w[model1 model2])
    end
  end

  describe '#prompt' do
    it 'replaces [initial_request] with first outgoing message body' do
      outgoing_message = instance_double(
        OutgoingMessage, body: 'message content'
      )
      insight = FactoryBot.build(
        :insight, template: 'Template with [initial_request]'
      )

      allow(insight).to receive(:outgoing_messages).
        and_return([outgoing_message])

      expect(insight.prompt).to eq('Template with message content')
    end
  end
end
