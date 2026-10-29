import json
import logging

import azure.functions as func

from drift import analyze_plan
from services.activity_log_client import find_activity
from services.ai_search_client import search_standards
from services.foundry_client import generate_recommendation


app = func.FunctionApp(http_auth_level=func.AuthLevel.FUNCTION)
MAX_PLAN_BYTES = 5 * 1024 * 1024


@app.route(route="investigate", methods=["POST"])
def investigate(request: func.HttpRequest) -> func.HttpResponse:
    if len(request.get_body()) > MAX_PLAN_BYTES:
        return func.HttpResponse(
            json.dumps({"error": "Terraform plan JSON exceeds the 5 MiB request limit."}),
            status_code=413,
            mimetype="application/json",
        )

    try:
        plan = request.get_json()
        report = analyze_plan(plan)
    except (ValueError, TypeError) as error:
        return func.HttpResponse(
            json.dumps({"error": str(error)}),
            status_code=400,
            mimetype="application/json",
        )

    warnings = []
    for drift in report["drifts"]:
        resource_id = drift.get("resource_id")
        if resource_id:
            try:
                drift["activity"] = find_activity(resource_id)
            except Exception:
                logging.exception("Activity Log lookup failed for %s", drift["address"])
                warnings.append(f"Activity Log lookup failed for {drift['address']}.")

        query = f"{drift['resource_type']} {drift['address']} " + " ".join(
            change["path"] for change in drift["changes"]
        )
        try:
            drift["knowledge_evidence"] = search_standards(query)
        except Exception:
            logging.exception("AI Search lookup failed for %s", drift["address"])
            drift["knowledge_evidence"] = []
            warnings.append(f"Azure AI Search lookup failed for {drift['address']}.")

    if report["drifts"]:
        try:
            report["recommendation"] = generate_recommendation(report)
        except Exception:
            logging.exception("Microsoft Foundry recommendation failed")
            warnings.append("Microsoft Foundry did not return a recommendation.")
            report["recommendation"] = None
    else:
        report["recommendation"] = None

    report["warnings"] = warnings
    return func.HttpResponse(
        json.dumps(report, default=str),
        status_code=200,
        mimetype="application/json",
    )