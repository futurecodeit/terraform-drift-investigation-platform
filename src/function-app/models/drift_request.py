from pydantic import BaseModel


class DriftRequest(BaseModel):

    terraform_plan: dict
