FROM python:3.12-slim

WORKDIR /app

COPY activity-log-mcp/requirements.txt ./requirements.txt

RUN pip install --no-cache-dir --default-timeout=600 --retries=5 -r requirements.txt

COPY activity-log-mcp/server.py ./server.py
COPY activity-log-mcp/routes.py ./routes.py
COPY common/ ./common/
COPY tools/ ./tools/

EXPOSE 8000

CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8000"]