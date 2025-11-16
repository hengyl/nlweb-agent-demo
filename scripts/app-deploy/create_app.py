import os
import requests
import json
from azure.identity import DefaultAzureCredential
from load_azd_env import load_azd_env

def call_azure_management_api(method: str, url: str, body=None):
    credential = DefaultAzureCredential()
    
    try:
        token = credential.get_token("https://management.azure.com/.default")
        headers = {
            "Authorization": f"Bearer {token.token}",
            "Content-Type": "application/json",
            "Accept": "application/json"
        }
        
        print(f"Calling Azure Management API with {method} method...")
        print(f"URL: {url}")
        
        if method.upper() == "GET":
            response = requests.get(url, headers=headers)
        elif method.upper() == "PUT":
            if body:
                print(f"Request body:")
                print(json.dumps(body, indent=2))
                response = requests.put(url, headers=headers, json=body)
            else:
                response = requests.put(url, headers=headers)
        else:
            raise ValueError(f"Unsupported HTTP method: {method}. Only GET and PUT are supported.")
        
        # Check if the request was successful
        if response.ok:
            print(f"API call successful! Status code: {response.status_code}")
            if response.content:
                result = response.json()
                #print(f"Response:")
                #print(json.dumps(result, indent=2))
                return result
            else:
                print("No response body")
                return {"status": "success", "status_code": response.status_code}
        else:
            print(f"API call failed with status code: {response.status_code}")
            print(f"Error response: {response.text}")
            return None
            
    except requests.RequestException as e:
        print(f"HTTP request error: {e}")
        return None
    except Exception as e:
        print(f"Unexpected error: {e}")
        return None

if __name__ == "__main__":
    load_azd_env()

    project_resource_id = os.environ.get("AI_FOUNDRY_PROJECT_RESOURCE_ID")
    agent_name = os.environ.get("AGENT_NLWEBAGENT_NAME")
    agent_version = os.environ.get("AGENT_NLWEBAGENT_VERSION")
    app_name = f"{agent_name}App"
    deployment_name = "deployment1"
   
    # Create app
    print(f"Creating application '{app_name}' for agent '{agent_name}'...")
    url = f"https://management.azure.com/{project_resource_id}/applications/{app_name}?api-version=2025-10-01-preview"
    result = call_azure_management_api("PUT", url, body={
        "properties": {
            "displayName": "NLWeb Application",
            "agents": [
              {
                "agentName": agent_name
              }
            ]
        }
    })

    # Create deployment
    print(f"Creating deployment '{deployment_name}' for application '{app_name}'...")
    url = f"https://management.azure.com/{project_resource_id}/applications/{app_name}/agentDeployments/{deployment_name}?api-version=2025-10-01-preview"
    result = call_azure_management_api("PUT", url, body={
        "properties": {
            "displayName": deployment_name,
            "deploymentType": "Hosted",
            "minReplicas": 1,
            "maxReplicas": 1,
            "protocols": [
              {
                "protocol": "MCP",
                "version": "1.0"
              }
            ],
            "agents": [
              {
                "agentName": agent_name,
                "agentVersion": agent_version
              }
            ]
        }
    })
