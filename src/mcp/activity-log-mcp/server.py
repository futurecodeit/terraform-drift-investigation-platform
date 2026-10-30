from fastapi import FastAPI
from azure.identity import DefaultAzureCredential
from azure.monitor.query import LogsQueryClient

app = FastAPI()

credential = DefaultAzureCredential()

client = LogsQueryClient(credential)