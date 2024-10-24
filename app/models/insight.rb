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
  admin_columns exclude: [:template, :output],
                include: [:duration, :prompt, :response]

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

  def duration
    return unless output['total_duration']

    seconds = output['total_duration'].to_f / 1_000_000_000
    ActiveSupport::Duration.build(seconds.to_i).inspect
  end

  def prompt
    template.gsub('[initial_request]') do
      outgoing_messages.first.body
    end
  end

  def response
    output['response']
  end

  private

  def queue
    InsightJob.perform_later(self)
  end
end
