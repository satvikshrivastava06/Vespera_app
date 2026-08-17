# Vespera Backend (Context-Aware RAG)

This is the FastAPI backend for the Vespera music streaming app. It uses Llama 3 (Groq) for AI curation and Pinecone for vector retrieval.

## Setup

1. **Environment Variables**:
   Edit `.env` and provide your API keys:
   - `GROQ_API_KEY`: [console.groq.com](https://console.groq.com)
   - `PINECONE_API_KEY`: [app.pinecone.io](https://app.pinecone.io)
   - `HF_TOKEN`: [huggingface.co](https://huggingface.co)

2. **Install Dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

3. **Populate Database (Crucial)**:
   This will create your Pinecone index and upload sample music vectors for the AI to find.
   ```bash
   python upload_songs.py
   ```

4. **Run Server**:
   ```bash
   python main.py
   ```

## Features
- **Context Analysis**: Uses LLM to determine the user's "vibe" based on time, location, and BPM.
- **Vector Search**: Fetches music from Pinecone index using RAG.
- **AI DJ**: Generates personalized AI DJ voice messages.
- **Dynamic Feed**: Provides dynamic news, rankings, and adaptive playlists.
