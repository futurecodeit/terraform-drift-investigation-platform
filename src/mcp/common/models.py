from pydantic import BaseModel


class ResourceRequest(BaseModel):
    resource_id: str


class UserRequest(BaseModel):
    upn: str


class SearchRequest(BaseModel):
    query: str