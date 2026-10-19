import json

class TerraformAnalyzerAgent:

    def analyze(self, tfplan_json):

        drifts = []

        for resource in tfplan_json["resource_changes"\]:

            if resource["change"]["actions"] != ["no-op"\]:

                drifts.append({
                    "resource_name":
                        resource["address"],

                    "resource_type":
                        resource["type"],

                    "before":
                        resource["change"]["before"],

                    "after":
                        resource["change"]["after"]
                })

        return drifts