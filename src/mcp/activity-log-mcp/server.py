from fastapi import FastAPI

from routes import router

app = FastAPI(
    title="Terraform Drift MCP Gateway"
)

app.include_router(router)