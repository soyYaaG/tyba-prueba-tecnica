FROM python:3.14-slim

COPY --from=ghcr.io/astral-sh/uv:0.9.18 /uv /uvx /usr/local/bin/

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    UV_LINK_MODE=copy \
    UV_NO_DEV=1 \
    PATH="/app/.venv/bin:${PATH}"

# Crear un usuario y grupo sin privilegios de root
ARG UID=1000
ARG GID=1000
RUN groupadd -g "${GID}" appuser \
    && useradd -u "${UID}" -g appuser -m -s /bin/bash appuser

WORKDIR /app

COPY pyproject.toml uv.lock README.md ./
RUN uv sync --frozen --no-dev --no-install-project

COPY config/ ./config/
COPY migrations/ ./migrations/
COPY sql/ ./sql/
COPY src/ ./src/
COPY main.py ./main.py
RUN mkdir -p /app/data/raw /app/data/output \
    && chown -R appuser:appuser /app

USER appuser

CMD ["uv", "run", "python", "main.py"]
