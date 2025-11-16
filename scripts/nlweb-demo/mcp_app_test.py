# ---------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# ---------------------------------------------------------

"""
DESCRIPTION:
    This sample demonstrates how to use NLWeb Hosted Agent MCP app endpoint.
"""

import os
import requests
from azure.identity import DefaultAzureCredential
from load_azd_env import load_azd_env

load_azd_env()

project_endpoint = os.environ.get("AZURE_AI_PROJECT_ENDPOINT")
api_version = "2025-11-15-preview"
if not project_endpoint:
    raise EnvironmentError("AZURE_AI_PROJECT_ENDPOINT not set. Please add it to a .env file or set the environment variable.")

agent_name = os.environ.get("AGENT_NLWEBAGENT_NAME")
agent_version = os.environ.get("AGENT_NLWEBAGENT_VERSION")
if not agent_name or not agent_version:
    raise EnvironmentError("AGENT_NLWEBAGENT_NAME or AGENT_NLWEBAGENT_VERSION not set. Please add it to a .env file or set the environment variable.")

credential = DefaultAzureCredential()

token = credential.get_token("https://ai.azure.com/.default")
headers = {
    "Authorization": f"Bearer {token.token}",
    "Content-Type": "application/json",
    "Accept": "application/json"
}

app_name = f"{agent_name}App"
app_endpoint = f"{project_endpoint}/applications/{app_name}/protocols/mcp?api-version=2025-11-15-preview"
print(f"Using Application Endpoint: {app_endpoint}")

input_json = {"jsonrpc": "2.0", "id": 1, "method": "tools/list"}

response = requests.post(app_endpoint, headers=headers, json=input_json)

print(f"Response status: {response.status_code}, text: {response.text}")
