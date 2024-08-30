LangchainrbRails.configure do |config|
  config.vectorsearch = Langchain::Vectorsearch::Pgvector.new(
    llm: Langchain::LLM::Ollama.new(
      url: ENV.fetch('OLLAMA_URL', 'http://127.0.0.1:11434'),
      default_options: {
        temperature: 0.0,
        completion_model_name: 'mistral',
        embeddings_model_name: 'mistral',
        chat_completion_model_name: 'mistral'
      }
    )
  )
end
