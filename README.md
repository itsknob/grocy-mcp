# grocy-mcp Docker Images

This directory contains Docker configurations for the `grocy-mcp` MCP server, allowing you to run it as a container.

## Quick Start

```bash
# 1. Build the image
docker build -t grocy-mcp:latest .

# 2. Run the container (stdio mode for MCP clients)
docker run -d \
  --name grocy-mcp \
  -e GROCY_URL=https://your-grocy-instance.com \
  -e GROCY_API_KEY=your-api-key \
  grocy-mcp:latest
```

## Transport Modes

### 1. stdio Transport (Default)
Used by MCP clients like **Claude Desktop**, **Claude Code**, and other MCP-aware applications.

**Docker run command:**
```bash
docker run -d \
  --name grocy-mcp \
  -e GROCY_URL=https://your-grocy-instance.com \
  -e GROCY_API_KEY=your-api-key \
  grocy-mcp:latest
```

**MCP Client Configuration** (e.g., Claude Desktop `config.json`):
```json
{
  "mcpServers": {
    "grocy": {
      "command": "docker exec grocy-mcp grocy-mcp",
      "args": [],
      "env": {
        "GROCY_URL": "https://your-grocy-instance.com",
        "GROCY_API_KEY": "your-api-key"
      }
    }
  }
}
```

### 2. Streamable HTTP Transport
For direct API access from your own applications or services.

**Docker run command:**
```bash
docker run -d \
  --name grocy-mcp-http \
  -e GROCY_URL=https://your-grocy-instance.com \
  -e GROCY_API_KEY=your-api-key \
  -e TRANSPORT=streamable-http \
  -p 8000:8000 \
  grocy-mcp:latest
```

**HTTP API Endpoint:** `https://your-grocy-instance.com:8000/mcp`

**Client-side usage:**
```bash
curl -X POST https://your-grocy-instance.com:8000/mcp \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-api-key" \
  -d '{"jsonrpc":"2.0","id":1,"method":"grocy.stock_overview","params":{}}'
```

### 3. Thin Image (Using pip)
For a smaller container that only includes the installed package:

```dockerfile
# Dockerfile.thin
FROM python:3.11-slim

RUN pip install --no-cache-dir grocy-mcp

USER grocy
EXPOSE 60999
CMD ["grocy-mcp"]
```

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `GROCY_URL` | **Yes** | - | Your Grocy instance URL (e.g., `https://grocy.example.com`) |
| `GROCY_API_KEY` | **Yes** | - | API key generated in Grocy settings |
| `TRANSPORT` | No | `stdio` | Transport mode: `stdio` or `streamable-http` |
| `HTTP_PORT` | No | `8000` | Port for HTTP transport |
| `MCP_PORT` | No | `60999` | Port for stdio transport |
| `HOST` | No | `0.0.0.0` | Bind address for HTTP transport |
| `PATH` | No | `/mcp` | MCP endpoint path for HTTP transport |

## Docker Compose

For production deployments, use the included `docker-compose.yml`:

```bash
# Copy the env file with your credentials
cp .env.example .env

# Build and run
docker compose up -d

# View logs
docker compose logs -f grocy-mcp

# Stop
docker compose down
```

### docker-compose Configuration

**stdio mode (MCP clients):**
```bash
docker compose --env-file .env -f docker-compose.yml up -d
```
Set `TRANSPORT=stdio` in the `.env` file

**HTTP mode (API access):**
```bash
docker compose --env-file .env -f docker-compose.yml up -d
```
Set `TRANSPORT=streamable-http` in the `.env` file

**Both modes:** Uncomment the HTTP port and run in http mode.

## Grocy Instance Connection

The MCP server needs to connect to your running Grocy instance:

### Option 1: Standalone Deployment
- Run Grocy on your server/VPS
- Run grocy-mcp in a separate container
- Configure network so they can communicate

### Option 2: Same Container (Development Only)
For development, you can install both Grocy and grocy-mcp in the same host:

```bash
docker run -d --name grocy grocy/grocy:v4.4.1+ -p 18080:80
docker run -d --name grocy-mcp -e GROCY_URL=http://localhost:18080 grocy-mcp
```

### Option 3: Docker Compose Stack
```bash
# docker-compose.yml (both services)
version: '3.8'

services:
  grocy:
    image: grocy/grocy:v4.4.1+
    ports:
      - "18080:80"
    volumes:
      - ./grocy-data:/var/www/html/vendor/grocy/data
    restart: unless-stopped

  grocy-mcp:
    build: ./Dockerfile
    depends_on:
      - grocy
    environment:
      - GROCY_URL=http://grocy:80
      - GROCY_API_KEY=your-api-key
    ports:
      - "60999:60999"
      - "8000:8000"
```

## Verification

Test that the server is running correctly:

```bash
# For stdio mode
docker exec grocy-mcp grocy system info

# For HTTP mode
curl http://localhost:8000/mcp/initialize
```

Expected output for `system info`:
```
Grocy version: 0.17.0
PHP version: 8.x
SQLite version: 3.x
```

## Security Notes

⚠️ **Important Security Considerations:**

1. **API Keys**: Never commit `GROCY_API_KEY` to version control. Use environment files.
2. **Network**: Restrict network access to your Grocy instance only.
3. **Authentication**: Ensure Grocy instance is properly secured.
4. **Least Privilege**: Create a Grocy API key with only necessary permissions.

## Troubleshooting

### "Connection failed" or timeouts
- Check that `GROCY_URL` is correct (should be the base URL, e.g., `https://grocy.example.com`)
- Verify your Grocy instance is accessible
- Check firewall rules and network connectivity

### "Auth failed (401)"
- Verify `GROCY_API_KEY` is correct
- Regenerate the key in Grocy: Settings → Manage API keys

### MCP client not connecting
- Verify the container is running: `docker ps`
- For Docker Desktop, use `host.docker.internal` for Grocy URL
- Check that port 60999 is accessible

### 503/Timeout errors
- Your Grocy instance might be overloaded
- Increase the connection timeout in Grocy settings
- Check server load and resources

## Docker Hub

Push your image to Docker Hub:

```bash
docker build -t grocy-mcp:latest .
docker login
docker tag grocy-mcp:latest attmous/grocy-mcp:latest
docker push attmous/grocy-mcp:latest
```

## License

MIT License
