FROM python:3.12-slim

ENV PYTHONUNBUFFERED 1
ENV POETRY_VERSION=1.8.2
ENV POETRY_HOME="/opt/poetry"
ENV POETRY_VENV_CREATE=false
ENV PATH="$POETRY_HOME/bin:$PATH"

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Poetry and Google Cloud SDK
RUN curl -sSL https://install.python-poetry.org | python3 -
RUN curl -sSL https://sdk.cloud.google.com | bash -s -- --disable-prompts
ENV PATH /root/google-cloud-sdk/bin:$PATH

WORKDIR /app/python/agents/data-science

COPY pyproject.toml ./

RUN poetry install --no-root --no-dev

COPY . .

EXPOSE 8000
CMD ["poetry", "run", "adk", "web", "--host", "0.0.0.0", "--port", "8000"]
