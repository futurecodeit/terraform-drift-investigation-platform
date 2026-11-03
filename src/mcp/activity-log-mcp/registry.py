from tools.activity_log import activity_log_lookup

from tools.resource_graph import query_resource_state

from tools.change_analysis import get_change_history

from tools.entra import resolve_user

from tools.pim import check_pim_activation

from tools.search import search_knowledge


TOOLS = {
    "activity_log_lookup": activity_log_lookup,
    "query_resource_state": query_resource_state,
    "get_change_history": get_change_history,
    "resolve_user": resolve_user,
    "check_pim_activation": check_pim_activation,
    "search_knowledge": search_knowledge
}