# LLMPatchbay2Dockerized

## 🐳 Run with Docker

```bash
docker build . -t patchbay
docker run -p 3036:3036 patchbay
```

Then open http://127.0.0.1:3036/Frontend/index.html in your browser.

⚠️ Beware: All data are lost when the container is restarted.
