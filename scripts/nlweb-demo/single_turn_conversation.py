# ---------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# ---------------------------------------------------------

"""
DESCRIPTION:
    This sample demonstrates how to have a single-turn conversation with
    a Hosted Agent using the synchronous client.
"""

import os
from azure.identity import DefaultAzureCredential
from azure.ai.projects import AIProjectClient
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

print(f"Using ProjectEndpoint: {project_endpoint}, Agent: {agent_name}, version: {agent_version}")

project_client = AIProjectClient(
    endpoint=project_endpoint,
    credential=DefaultAzureCredential(),
    api_version=api_version
)
with project_client:

    openai_client = project_client.get_openai_client()

    # Example inputs for mcp request
    input_text = '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'
    # input_text = '{"jsonrpc":"2.0","id":1,"method": "tools/call","params":{"name": "ask","arguments":{"query": "AI podcast"}}}'

    print(f"Sending request: {input_text}")

    response = openai_client.responses.create(
        input=input_text,
        extra_body={"agent": { "type": "agent_reference", "name": agent_name, "version": agent_version }}
    )
    print(f"Response status: {response.status}, text: {response.output_text}")
