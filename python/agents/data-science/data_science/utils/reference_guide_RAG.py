# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import os
from pathlib import Path
from dotenv import load_dotenv, set_key
import vertexai
from vertexai import rag


# Define the path to the .env file
env_file_path = Path(__file__).parent.parent.parent / ".env"
print(env_file_path)

# Load environment variables from the specified .env file
load_dotenv(dotenv_path=env_file_path)

PROJECT_ID = os.getenv("GOOGLE_CLOUD_PROJECT")
corpus_name = os.getenv("BQML_RAG_CORPUS_NAME")

display_name = "bqml_referenceguide_corpus"

paths = [
    "gs://cloud-samples-data/adk-samples/data-science/bqml"
]  # Supports Google Cloud Storage and Google Drive Links


# Initialize Vertex AI API once per session
vertexai.init(project=PROJECT_ID, location="us-central1")


def create_RAG_corpus():
    """
    Creates a RAG corpus if it doesn't already exist with the specified display_name.
    If it exists, it uses the existing one.
    """
    print(f"Checking for existing RAG corpus with display name: {display_name}")
    corpora = rag.list_corpora()
    existing_corpus = None
    for corpus in corpora:
        if corpus.display_name == display_name:
            existing_corpus = corpus
            break

    if existing_corpus:
        print(f"Found existing RAG corpus: {existing_corpus.name}")
        corpus_resource_name = existing_corpus.name
    else:
        print(f"RAG corpus '{display_name}' not found. Creating a new one...")
        # Configure embedding model, for example "text-embedding-005".
        embedding_model_config = rag.RagEmbeddingModelConfig(
            vertex_prediction_endpoint=rag.VertexPredictionEndpoint(
                publisher_model="publishers/google/models/text-embedding-005"
            )
        )

        backend_config = rag.RagVectorDbConfig(
            rag_embedding_model_config=embedding_model_config
        )

        new_corpus = rag.create_corpus(
            display_name=display_name,
            backend_config=backend_config,
        )
        print(f"Successfully created RAG corpus: {new_corpus.name}")
        corpus_resource_name = new_corpus.name

    write_to_env(corpus_resource_name)
    return corpus_resource_name


def ingest_files(corpus_name):

    transformation_config = rag.TransformationConfig(
        chunking_config=rag.ChunkingConfig(
            chunk_size=512,
            chunk_overlap=100,
        ),
    )

    rag.import_files(
        corpus_name,
        paths,
        transformation_config=transformation_config,  # Optional
        max_embedding_requests_per_min=1000,  # Optional
    )

    # List the files in the rag corpus
    rag.list_files(corpus_name)


def rag_response(query: str) -> str:
    """Retrieves contextually relevant information from a RAG corpus.

    Args:
        query (str): The query string to search within the corpus.

    Returns:
        vertexai.rag.RagRetrievalQueryResponse: The response containing retrieved
        information from the corpus.
    """
    corpus_name = os.getenv("BQML_RAG_CORPUS_NAME")

    rag_retrieval_config = rag.RagRetrievalConfig(
        top_k=3,  # Optional
        filter=rag.Filter(vector_distance_threshold=0.5),  # Optional
    )
    response = rag.retrieval_query(
        rag_resources=[
            rag.RagResource(
                rag_corpus=corpus_name,
            )
        ],
        text=query,
        rag_retrieval_config=rag_retrieval_config,
    )
    return str(response)


def write_to_env(corpus_name):
    """Writes the corpus name to the specified .env file.

    Args:
        corpus_name: The name of the corpus to write.
    """

    load_dotenv(env_file_path)  # Load existing variables if any

    # Set the key-value pair in the .env file
    set_key(env_file_path, "BQML_RAG_CORPUS_NAME", corpus_name)
    print(f"BQML_RAG_CORPUS_NAME '{corpus_name}' written to {env_file_path}")


if __name__ == "__main__":
    # Check if corpus_name is already in .env, if not, create/get it.
    # This handles the case where the script might be run multiple times.
    # The create_RAG_corpus function is idempotent based on display_name.
    current_corpus_name = os.getenv("BQML_RAG_CORPUS_NAME")
    if not current_corpus_name:
        print("BQML_RAG_CORPUS_NAME not found in .env, attempting to create or find existing corpus.")

    final_corpus_name = create_RAG_corpus() # This will either create or find existing
    print(f"Ensured RAG corpus is available: {final_corpus_name}")
    print(f"Importing files to corpus: {final_corpus_name}...")
    ingest_files(final_corpus_name)
    print(f"Files imported to corpus: {final_corpus_name}.")
