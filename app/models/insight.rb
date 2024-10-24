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
class Insight < ApplicationRecord
  after_commit :queue, on: :create

  belongs_to :info_request, optional: false
  has_many :outgoing_messages, through: :info_request

  serialize :output, type: Hash, coder: JSON, default: {}

  validates :model, presence: true
  validates :template, presence: true

  def self.client
    @client ||= Ollama.new(
      credentials: { address: ENV['OLLAMA_URL'] },
      options: { server_sent_events: true }
    )
  end

  def self.models
    client.tags.first['models'].map { _1['model'] }.sort
  end

  def prompt
    template.gsub('[initial_request]') do
      outgoing_messages.first.body
    end
  end

  private

  def queue
    InsightJob.perform_later(self)
  end
end
