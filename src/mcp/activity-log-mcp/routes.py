import os

from fastapi import APIRouter

from common.models import (
    ResourceRequest,
    UserRequest,
    SearchRequest
)

from tools.activity_log import activity_log_lookup

from tools.change_analysis import get_change_history

from tools.resource_graph import query_resource_state

from tools.entra import resolve_user

from tools.pim import check_pim_activation

from tools.search import search_knowledge

router = APIRouter()


@router.get("/health")
def health():
    return {"status": "healthy"}


@router.post("/tools/activity-log")
def activity_tool(request: ResourceRequest):

    return activity_log_lookup(
        request.resource_id
    )


@router.post("/tools/change-analysis")
def change_analysis_tool(request: ResourceRequest):

    return get_change_history(
        request.resource_id
    )


@router.post("/tools/resource-graph")
def graph_tool(request: ResourceRequest):

    return query_resource_state(
        subscription_id=os.environ["SUBSCRIPTION_ID"],
        resource_id=request.resource_id
    )


@router.post("/tools/entra")
def entra_tool(request: UserRequest):

    return resolve_user(
        request.upn
    )


@router.post("/tools/pim")
def pim_tool(request: UserRequest):

    return check_pim_activation(
        request.upn
    )


@router.post("/tools/search")
def search_tool(request: SearchRequest):

    return search_knowledge(
        request.query
    )