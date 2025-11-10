# Copyright (c) 2025 Microsoft Corporation.
# Licensed under the MIT License

"""
This file is the entry point for the NLWeb Sample App as agent.

WARNING: This code is under development and may undergo changes in future releases.
Backwards compatibility is not guaranteed at this time.
"""

import json
import nlweb_core
from pathlib import Path
from typing import Dict, TypedDict, List, Any
from dotenv import load_dotenv
from aiohttp import web
from langgraph.graph import StateGraph, END, MessagesState
from langchain_core.messages import AIMessage
from azure.ai.agentserver.langgraph import from_langgraph
from nlweb_core.NLWebVectorDBRankingHandler import NLWebVectorDBRankingHandler
from mcp_handler import MCPHandler
from output_response import OutputResponse
from utils import is_json_rpc_message, extract_text 

# Define the state structure
class GraphState(TypedDict):
    query: str
    search_results: str

async def do_nlweb_query(msg: str) -> str:
    ## fall back to run regular nlweb query
    try:
        query_params: Dict[str, Any] = {
            "query": msg,
            "site": ["all"],
            "mode": ["list"],
            "streaming": "false",
        }

        output_response = OutputResponse()
        output_method = output_response.create_collector_output_method()

        handler = NLWebVectorDBRankingHandler(query_params, output_method)
        # Run the query - it will return the complete response
        await handler.runQuery()
        responses = output_response.get_collected_responses()
        result = output_response.build_json_response(responses)

        responsestr = web.json_response(result)
        return responsestr.text
    except Exception as e:
        print(f"Error in do_nlweb_query: {e}")
        return f"Error processing request: {str(e)}"

async def run_nlweb_mcp(state: MessagesState) -> MessagesState:
    # Get the content from the last message properly
    last_user_message = state['messages'][-1].content
    msg = extract_text(last_user_message)

    # Check if the message is JSON-RPC
    mcp_handler = MCPHandler()
    response_content = ""
    if is_json_rpc_message(msg):
        request_data = json.loads(msg)
        response = await mcp_handler.handle_request(request_data)
        response_data = json.dumps(response).encode('utf-8')
        response_content = response_data if response_data else "No response from MCP handler"
        agent_response = AIMessage(content=response_content)
        # Return new state with the agent's message appended
        return {
            **state,
            "messages": state["messages"] + [agent_response]
        }
    else:
        # fall back to regular nlweb query, testing purpose only
        responsestr = await do_nlweb_query(msg)
        agent_response = AIMessage(content=responsestr)
        return {
            **state,
            "messages": state["messages"] + [agent_response]
        }

# env_path = Path(__file__).parent / ".env"
# load_dotenv(dotenv_path=env_path)

# Create the workflow graph
workflow = StateGraph(MessagesState)

workflow.add_node("nlweb", run_nlweb_mcp)

# Define the flow
workflow.set_entry_point("nlweb")
workflow.add_edge("nlweb", END)

agent = workflow.compile()

config_path = Path(__file__).parent / "config.yaml"
nlweb_core.init(config_path=str(config_path))

if __name__ == "__main__":
    adapter = from_langgraph(agent)
    adapter.run()
