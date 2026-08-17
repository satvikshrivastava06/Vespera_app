import os
import requests
from pinecone import Pinecone
from dotenv import load_dotenv

load_dotenv()

# Config
GROQ_API_KEY = os.getenv("GROQ_API_KEY")
PINECONE_API_KEY = os.getenv("PINECONE_API_KEY")
PINECONE_INDEX_NAME = os.getenv("PINECONE_INDEX_NAME", "vespera-index")
HF_TOKEN = os.getenv("HF_TOKEN")

# Initialize Pinecone
pc = Pinecone(api_key=PINECONE_API_KEY)

def get_hf_embedding(text: str):
    model_id = "sentence-transformers/all-MiniLM-L6-v2"
    api_url = f"https://api-inference.huggingface.co/pipeline/feature-extraction/{model_id}"
    headers = {"Authorization": f"Bearer {HF_TOKEN}"}
    response = requests.post(api_url, headers=headers, json={"inputs": [text]})
    if response.status_code == 200:
        return response.json()[0]
    raise Exception(f"HF Error: {response.text}")

def create_index_if_not_exists():
    if PINECONE_INDEX_NAME not in pc.list_indexes().names():
        print(f"Creating index {PINECONE_INDEX_NAME}...")
        pc.create_index(
            name=PINECONE_INDEX_NAME,
            dimension=384, # all-MiniLM-L6-v2 dimension
            metric="cosine",
            spec={"serverless": {"cloud": "aws", "region": "us-east-1"}}
        )
        print("Index created successfully.")
    else:
        print(f"Index {PINECONE_INDEX_NAME} already exists.")

def upload_sample_songs():
    index = pc.Index(PINECONE_INDEX_NAME)
    
    songs = [
        {"id": "1", "title": "Starboy", "artist": "The Weeknd", "genre": "Pop", "bpm": 186, "vibe": "Energetic, Dark, Night"},
        {"id": "2", "title": "Blinding Lights", "artist": "The Weeknd", "genre": "Synth-pop", "bpm": 171, "vibe": "High Energy, Retro, Driving"},
        {"id": "3", "title": "In Your Eyes", "artist": "The Weeknd", "genre": "R&B", "bpm": 100, "vibe": "Smooth, Romantic, Evening"},
        {"id": "4", "title": "Save Your Tears", "artist": "The Weeknd", "genre": "Pop", "bpm": 118, "vibe": "Melancholic, Groovy, Sunset"},
        {"id": "5", "title": "Midnight City", "artist": "M83", "genre": "Electronic", "bpm": 105, "vibe": "Cinematic, Night, Uplifting"}
    ]
    
    print("Uploading songs to Pinecone...")
    vectors = []
    for song in songs:
        embedding = get_hf_embedding(f"{song['title']} {song['artist']} {song['genre']} {song['vibe']}")
        vectors.append({
            "id": song["id"],
            "values": embedding,
            "metadata": {
                "title": song["title"],
                "artist": song["artist"],
                "genre": song["genre"],
                "bpm": song["bpm"],
                "image_url": f"https://picsum.photos/seed/{song['id']}/400/400"
            }
        })
    
    index.upsert(vectors=vectors)
    print("Done! Database populated with sample songs.")

if __name__ == "__main__":
    if not HF_TOKEN or not PINECONE_API_KEY:
        print("Please set your API keys in .env first!")
    else:
        create_index_if_not_exists()
        upload_sample_songs()
