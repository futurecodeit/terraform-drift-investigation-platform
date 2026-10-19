class CorrelationAgent:

    def correlate(
            self,
            drift,
            activity,
            change,
            identity,
            rag):

        return {

            "resource":
                drift["resource_name"],

            "changed_by":
                identity["user"],

            "role":
                identity["role"],

            "pim":
                identity["pim"],

            "property":
                change["property"],

            "old":
                change["old"],

            "new":
                change["new"],

            "expected":
                rag[0]["content"]
        }