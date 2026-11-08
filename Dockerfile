# Dockerfile for grocy-mcp MCP server
# Supports both stdio and streamable-http transport modes
#
# Usage:
#   # stdio mode (for MCP clients like Claude Desktop)
#   docker run -e GROCY_URL=https://grocy.example.com \
#              -e GROCY_API_KEY=your-api-key \
#              grocy-mcp:latest
#
#   # http mode (for direct API access)
#   docker run -e GROCY_URL=https://grocy.example.com \
#              -e GROCY_API_KEY=your-api-key \
#              -e TRANSPORT=streamable-http \
#              -p 8000:8000 \
#              grocy-mcp:latest

FROM python:3.11-slim

# Environment variables for Python and MCP
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    TRANSport=stdio

# Create a non-root user for security
RUN groupadd -r grocy && useradd -r -g grocy grocy

# Set working directory
WORKDIR /app

# Copy project files
COPY src/ ./src/
COPY pyproject.toml ./
COPY README.md ./

# Install the package and dependencies
RUN pip install --no-cache-dir -e ".[dev]"

# Health check to verify the server is running
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD grocy-mcp --transport stdio grocy system info || exit 1

# Default command (stdio mode by default)
CMD ["grocy-mcp"]
