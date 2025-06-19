# LLMPatchbay: Visual AI Workflow Engine

LLMPatchbay is a powerful backend for building visual, block-based data processing and AI pipelines. It uses a "patch bay" metaphor, allowing you to connect various components—like LLM providers, databases, and custom logic—to create complex and repeatable workflows.

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

From the root of the project, run the build command. This will install all dependencies, set up the PostgreSQL server, and initialize the database schema from `sql_template.sql`.

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
    
    # TO:
    RUN curl -fsSL https://ollama.com/install.sh | sh
    ```
2.  **Re-build the Image:** You must rebuild the image for the change to take effect.
    ```bash
    docker build . -t patchbay
    ```
3.  **Use Ollama in `entrypoint.sh`:** Your `entrypoint.sh` script should be updated to start the Ollama service alongside your other services. You can then pull models by executing a command inside the running container:
    ```bash
    docker exec -it patchbay-app ollama run gemma2
    ```

---
---

### **Action Required: Code & Project Changes**

Here is a checklist of changes to make to your files. These changes align your project with the improved `README.md`, add data persistence, and increase security.

#### **1. Add a `VOLUME` instruction to your `Dockerfile`**

This instruction formally declares that the PostgreSQL data directory should be managed externally, making it work seamlessly with the `docker run -v` command.

*   **File:** `Dockerfile`
*   **Action:** Add the following line just before the `WORKDIR` instruction.

```dockerfile
# ... (near the end of the file)

RUN /etc/init.d/postgresql start && \
    until pg_isready -U postgres; do echo "Waiting for PostgreSQL..."; sleep 1; done && \
    psql -U postgres --command "CREATE USER docker WITH SUPERUSER PASSWORD 'docker';" 2>&1 | tee /tmp/psql_create_user.log && \
    createdb -U docker llm_patchbay 2>&1 | tee /tmp/psql_createdb.log && \
    psql -U docker llm_patchbay < /app/sql_template.sql 2>&1 | tee /tmp/psql_import.log

# --- ADD THIS LINE ---
VOLUME /var/lib/postgresql/17/main
# ---------------------

# RUN curl -fsSL https://ollama.com/install.sh | sh
# ...
```

#### **2. Update the Database Connection String in your Perl code**

Your `Dockerfile` creates a user named `docker` with the password `docker`. Your Perl code is trying to connect as the user `postgres` with no password. You need to make them match.

*   **File:** Your Perl Script (`.pl`)
*   **Action:** Modify the `pg` helper.

```perl
# --- BEFORE (Your current code) ---
helper pg => sub { state $pg = Mojo::Pg->new('postgresql://postgres@localhost/llm_patchbay') };


# --- AFTER (The new code) ---
helper pg => sub { state $pg = Mojo::Pg->new('postgresql://docker:docker@localhost/llm_patchbay') };
```

#### **3. Use an Environment Variable for the API Key**

Hardcoding secrets is a security risk. This change makes your application read the API key from the environment, which you provide in the `docker run` command.

*   **File:** Your Perl Script (`.pl`)
*   **Action:** Apply this change in the `get_embedding` and `run_llm` helpers, or anywhere the bearer token is used.

```perl
# --- BEFORE (Example from your 'run_llm' helper) ---
$ua->on(start => sub    {
    my ($ua, $tx) = @_;
    $tx->req->headers->authorization("Bearer 36a3430b2d9473438a1447b5f24f69fc");
});


# --- AFTER (The secure, new code) ---
$ua->on(start => sub    {
    my ($ua, $tx) = @_;
    if (my $api_key = $ENV{API_BEARER_TOKEN}) {
        $tx->req->headers->authorization("Bearer $api_key");
    }
});
```
*You must apply this pattern to **all** places where the hardcoded token `36a3430b2d9473438a1447b5f24f69fc` appears.*

#### **4. (Recommended) Improve your `entrypoint.sh`**

Starting the database during the `docker build` (`RUN`) is not ideal because its state gets baked into the image layer. A better practice is to start services when the *container runs*.

*   **File:** `entrypoint.sh`
*   **Action:** Ensure your `entrypoint.sh` starts the PostgreSQL service and then your application.

**Example `entrypoint.sh`:**
```bash
#!/bin/bash

# Start PostgreSQL
/etc/init.d/postgresql start

# (Optional) Start Ollama if it's installed
# if [ -f /usr/local/bin/ollama ]; then
#   ollama serve &
# fi

# Start the Mojolicious application
# The 'hypnotoad' line from your source code suggests you are running a production server.
# Using 'hypnotoad' directly might be better.
hypnotoad /app/your_script_name.pl

# Keep the container running if hypnotoad runs in the background
# This might not be needed depending on how hypnotoad behaves.
# tail -f /dev/null
```
If you do this, you can **remove** the `/etc/init.d/postgresql start` command from the long `RUN` instruction in your `Dockerfile`, making your builds faster and your images more stateless.
