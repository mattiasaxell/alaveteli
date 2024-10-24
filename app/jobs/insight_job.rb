##
# InsightJob is responsible for generating InfoRequest insights using an AI
# model run via Ollama.
#
class InsightJob < ApplicationJob
  queue_as :insights

  delegate :model, :prompt, to: :@insight

  def perform(insight)
    @insight = insight

    insight.update(output: results.first)
  end

  private

  def results
    Insight.client.generate({ model: model, prompt: prompt, stream: false })
  end
end
