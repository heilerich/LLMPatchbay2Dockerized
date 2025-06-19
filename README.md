# LLMPatchbay: Visual AI Workflow Engine

LLMPatchbay is a powerful backend for building visual, block-based data processing and AI pipelines. It uses a "patch bay" metaphor, allowing you to connect various components—like LLM providers, databases, and custom logic—to create complex and repeatable workflows **and expose these via a RESTFul API**.

This project is packaged as a self-contained Docker image that includes the Perl/Mojolicious application, a PostgreSQL server with `pgvector`, and an R environment.

## ✨ Features

*   **Visual Workflow Engine:** A backend for a UI where you connect processing blocks.
*   **LLM Integration:**
    *   Connect to local models via **Ollama** (optional).
    *   Integrate with external inference APIs.
*   **Vector Search (RAG):**
    *   Store and manage embedding datasets using `pgvector`.
    *   Perform dense retrieval (similarity search) for RAG pipelines.
*   **Rich Data Processing Blocks:**
    *   Text manipulation (sprintf, regex), data fetching (HTTP), parsing (JSON, XML), and statistical analysis with **R**.
*   **Self-Contained & Persistent:** Runs in a single Docker container with persistent database storage.

## 🚀 Getting Started with Docker

### 1. Build the Docker Image

From the root of the project, run the build command. This will install all dependencies, set up the PostgreSQL server, and initialize the database schema.

```bash
docker build . -t patchbay
```

### 2. Run the Container (with Persistent Data)

To ensure your database data **is not lost** when the container stops or restarts, you must run it with a named volume. This command maps a volume on your host machine to the PostgreSQL data directory inside the container.

```bash
docker run -d \
  --name patchbay-app \
  -p 3036:3036 \
  -v patchbay-data:/var/lib/postgresql/17/main \
  -e API_BEARER_TOKEN="your_secret_api_key_here" \
  patchbay
```
*   `-d`: Run in detached mode (in the background).
*   `--name patchbay-app`: Give the container a memorable name.
*   `-p 3036:3036`: Map the container's port to your local machine.
*   `-v patchbay-data:/var/lib/postgresql/17/main`: **Crucial!** This creates a persistent volume named `patchbay-data` for the database.
*   `-e API_BEARER_TOKEN="..."`: Sets your API key as an environment variable for better security.

### 3. Access The Application
Open your browser and navigate to:
**[http://127.0.0.1:3036/Frontend/index.html](http://127.0.0.1:3036/Frontend/index.html)**

To see logs from the running container:
```bash
docker logs -f patchbay-app
```

---

## ⚙️ Configuration

### Data Persistence

The `-v patchbay-data:/var/lib/postgresql/17/main` argument in the `docker run` command is essential. It tells Docker to store the database files outside the container's ephemeral filesystem. Without it, **all data will be lost** when you remove the container.

### Enabling Ollama Support

The `Dockerfile` is prepared for Ollama integration, but it is commented out by default. To enable it:

1.  **Edit your `Dockerfile`:** Uncomment the lines related to Ollama installation.
    ```dockerfile
    # FROM:
    # RUN curl -fsSL https://ollama.com/install.sh | sh
    # COPY install_ollama.sh /app
    # RUN /app/install_ollama.sh

    # TO:
    RUN curl -fsSL https://ollama.com/install.sh | sh
    COPY install_ollama.sh /app
    RUN /app/install_ollama.sh

    ```
2.  **Re-build the Image:** You must rebuild the image for the change to take effect.
    ```bash
    docker build . -t patchbay
    ```
3.  **Use Ollama in `entrypoint.sh`:** Your `entrypoint.sh` script should be updated to start the Ollama service alongside your other services. You can then pull models by executing a command inside the running container:
    ```bash
    docker exec -it patchbay-app ollama run gemma2
    ```
