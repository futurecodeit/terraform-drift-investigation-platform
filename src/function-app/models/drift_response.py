from pydantic import BaseModel


class DriftResponse(BaseModel):

    resource: str

    changed_by: str

    change_type: str

    recommendation: str
