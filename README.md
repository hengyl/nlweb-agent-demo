# Getting Started with NLWeb Foundry

The agent leverages the Azure AI Agent service and enable NLWeb as MCP endpoint.

[**Features**](#features) \| [**Prerequisites**](#prerequisites) \| [**Getting Started**](#getting-started) \| [**Local Development**](#local-development) \| [**Resources Clean-Up**](#resource-clean-up) \| [**Guidance**](#guidance) \| [**Troubleshooting**](#troubleshooting)

## Important Security Notice

This template, the application code and configuration it contains, has been built to showcase Microsoft Azure specific services and tools. We strongly advise our customers not to make this code part of their production environments without implementing or enabling additional security features.

## Features

This project framework provides the following features:

* **Azure AI Foundry Project**: Complete setup of Azure AI Foundry workspace with project configuration
* **Foundry Model Deployments**: Automatic deployment of AI models for agent capabilities
* **Container-Based Agent Hosting**: NLWeb application as Foundry hosted agent for deploying and scaling AI agents
* **Azure Container Registry**: Secure container image storage and management for agent deployments
* **Managed Identity**: Built-in Azure Managed Identity for secure, keyless authentication between services
* **Infrastructure as Code**: Complete Bicep templates for repeatable, version-controlled deployments

## Prerequisites

You will need the following services to use this template.

* Azure Developer CLI (azd)
* Bicep (installed with azd)
* Docker
  * On Windows: ```winget install Docker.DockerDesktop```
  * On Mac:  ```brew install --cask docker```

## Configuration

The project uses a centralized `config.yaml` file at the root level to configure:

* **LLM settings**: Azure OpenAI models (gpt-4o for high-complexity, gpt-4o-mini for low-complexity tasks)
* **Embedding settings**: Text embedding model configuration
* **Retrieval settings**: Azure AI Search configuration   //FUTURE: Add other data source endpoints
* **Data sources**: RSS feeds and other data sources to load

You can customize model names, API endpoints, and data sources by editing `/config.yaml` before deployment.

## Getting Started

1. Clone the repo
2. This repo use the new azd to deploy agent. Please install the latest azd build 1.21.1 or higher.

   ### Windows Install

   ```pwsh
   winget install microsoft.azd
   ```

   ### Mac / Liunx Install

   ```bash
   brew install azure/azd/azd
   ```

   ### Verify Version

   ```pwsh
   azd version
   ```

   It should show ```azd version 1.21.1``` or higher.

3. Start Docker Desktop

   * On Windows: ```start docker```
   * On Mac:  ```docker ps```

4. Run ```azd env new``` in the terminal to create a new environment

5. Run ```azd up``` in the terminal. Follow the prompts to select your Azure subscription and region.

   **Supported regions:** East US, East US 2, Sweden Central, or West US 2

   > **Note:** Region availability may vary based on Azure capacity and your subscription's quota. If deployment fails with a model availability error, try a different region.

   * The NLWeb agent code is at /app/NLWebAgent. This is used to build a docker image.
   * Several features require to opt-in your subscription. Please contact the team to enable your subscriptions.

   > **Deployment Tip:** If you encounter a precondition failure (IfMatchPreconditionFailed) during model deployment, this is a timing issue with Azure processing multiple model deployments. Simply run `azd up` again and it will continue from where it left off.

6. Wait for deployment to complete (5-10 minutes). What it does:

   * Provision AI Foundry Project and Azure AI Search.
   * Load the sample data to Azure AI Search.
   * Deploy NLWeb as the hosted agent in AI Foundry Project.
   * Create agent application

7. Test using script/nlweb-demo/mcp_app_test.py and send MCP tools/list request

   ```pwsh
   # create a python venv 
   cd scripts/nlweb-demo
   pip install -r ./requirements.txt
   python ./mcp_app_test.py
   ```

   It sends MCP request tools/list and you should see the MCP response from the NLWeb agent.

For detailed deployment options and troubleshooting, see the [full deployment guide](./docs/deployment.md).
**After deployment, try these [sample questions](./docs/sample_questions.md) to test your agent.**

## Local Development

For developers who want to run the application locally or customize the agent:

- **[Local Development Guide](./docs/local_development.md)** - Set up a local development environment, customize the frontend (starting with AgentPreview.tsx), modify agent instructions and tools, and use evaluation to improve your code.

This guide covers:
- Environment setup and prerequisites
- Running the development server locally
- Frontend customization and backend communication
- Agent instructions and tools modification
- File management and agent recreation
- Using agent evaluation for code improvement


## Resource Clean-up

To prevent incurring unnecessary charges, it's important to clean up your Azure resources after completing your work with the application.

- **When to Clean Up:**
  - After you have finished testing or demonstrating the application.
  - If the application is no longer needed or you have transitioned to a different project or environment.
  - When you have completed development and are ready to decommission the application.

- **Deleting Resources:**
  To delete all associated resources and shut down the application, execute the following command:
  
    ```bash
    azd down
    ```

    Please note that this process may take up to 20 minutes to complete.

⚠️ Alternatively, you can delete the resource group directly from the Azure Portal to clean up resources.

## Guidance

### Costs

Pricing varies per region and usage, so it isn't possible to predict exact costs for your usage.
The majority of the Azure resources used in this infrastructure are on usage-based pricing tiers.

You can try the [Azure pricing calculator](https://azure.microsoft.com/pricing/calculator) for the resources:

- **Azure AI Foundry**: Free tier. [Pricing](https://azure.microsoft.com/pricing/details/ai-studio/)  
- **Azure AI Services**: S0 tier, defaults to gpt-4o-mini. Pricing is based on token count. [Pricing](https://azure.microsoft.com/pricing/details/cognitive-services/)  
- **Log analytics**: Pay-as-you-go tier. Costs based on data ingested. [Pricing](https://azure.microsoft.com/pricing/details/monitor/)  

⚠️ To avoid unnecessary costs, remember to take down your app if it's no longer in use,
either by deleting the resource group in the Portal or running `azd down`.

### Security guidelines

This template also uses [Managed Identity](https://learn.microsoft.com/entra/identity/managed-identities-azure-resources/overview) for local development and deployment.

To ensure continued best practices in your own repository, we recommend that anyone creating solutions based on our templates ensure that the [Github secret scanning](https://docs.github.com/code-security/secret-scanning/about-secret-scanning) setting is enabled.

You may want to consider additional security measures, such as:

- Enabling Microsoft Defender for Cloud to [secure your Azure resources](https://learn.microsoft.com/azure/defender-for-cloud/).
- Protecting the Azure Container Apps instance with a [firewall](https://learn.microsoft.com/azure/container-apps/waf-app-gateway) and/or [Virtual Network](https://learn.microsoft.com/azure/container-apps/networking?tabs=workload-profiles-env%2Cazure-cli).

### Resources

This template creates everything you need to get started with Azure AI Foundry:

| Resource | Description |
|----------|-------------|
| [Azure AI Project](https://learn.microsoft.com/azure/ai-studio/how-to/create-projects) | Provides a collaborative workspace for AI development with access to models, data, and compute resources |
| [Azure OpenAI Service](https://learn.microsoft.com/azure/ai-services/openai/) | Powers the AI agents for conversational AI and intelligent search capabilities. Default models deployed are gpt-4o-mini, but any Azure AI models can be specified per the [documentation](docs/deploy_customization.md#customizing-model-deployments) |
| [Azure Container Registry](https://learn.microsoft.com/azure/container-registry/) | Stores and manages container images for secure deployment |
| [AI Search Service](https://learn.microsoft.com/azure/search/) | *Optional* - Enables hybrid search capabilities combining semantic and vector search |
| [Application Insights](https://learn.microsoft.com/azure/azure-monitor/app/app-insights-overview) | *Optional* - Provides application performance monitoring, logging, and telemetry for debugging and optimization |
| [Log Analytics Workspace](https://learn.microsoft.com/azure/azure-monitor/logs/log-analytics-workspace-overview) | *Optional* - Collects and analyzes telemetry data for monitoring and troubleshooting |

## Troubleshooting

For solutions to common deployment, container app, and agent issues, see the [Troubleshooting Guide](./docs/troubleshooting.md).


## Disclaimers

To the extent that the Software includes components or code used in or derived from Microsoft products or services, including without limitation Microsoft Azure Services (collectively, “Microsoft Products and Services”), you must also comply with the Product Terms applicable to such Microsoft Products and Services. You acknowledge and agree that the license governing the Software does not grant you a license or other right to use Microsoft Products and Services. Nothing in the license or this ReadMe file will serve to supersede, amend, terminate or modify any terms in the Product Terms for any Microsoft Products and Services.

You must also comply with all domestic and international export laws and regulations that apply to the Software, which include restrictions on destinations, end users, and end use. For further information on export restrictions, visit <https://aka.ms/exporting>.

You acknowledge that the Software and Microsoft Products and Services (1) are not designed, intended or made available as a medical device(s), and (2) are not designed or intended to be a substitute for professional medical advice, diagnosis, treatment, or judgment and should not be used to replace or as a substitute for professional medical advice, diagnosis, treatment, or judgment. Customer is solely responsible for displaying and/or obtaining appropriate consents, warnings, disclaimers, and acknowledgements to end users of Customer’s implementation of the Online Services.

You acknowledge the Software is not subject to SOC 1 and SOC 2 compliance audits. No Microsoft technology, nor any of its component technologies, including the Software, is intended or made available as a substitute for the professional advice, opinion, or judgement of a certified financial services professional. Do not use the Software to replace, substitute, or provide professional financial advice or judgment.  

BY ACCESSING OR USING THE SOFTWARE, YOU ACKNOWLEDGE THAT THE SOFTWARE IS NOT DESIGNED OR INTENDED TO SUPPORT ANY USE IN WHICH A SERVICE INTERRUPTION, DEFECT, ERROR, OR OTHER FAILURE OF THE SOFTWARE COULD RESULT IN THE DEATH OR SERIOUS BODILY INJURY OF ANY PERSON OR IN PHYSICAL OR ENVIRONMENTAL DAMAGE (COLLECTIVELY, “HIGH-RISK USE”), AND THAT YOU WILL ENSURE THAT, IN THE EVENT OF ANY INTERRUPTION, DEFECT, ERROR, OR OTHER FAILURE OF THE SOFTWARE, THE SAFETY OF PEOPLE, PROPERTY, AND THE ENVIRONMENT ARE NOT REDUCED BELOW A LEVEL THAT IS REASONABLY, APPROPRIATE, AND LEGAL, WHETHER IN GENERAL OR IN A SPECIFIC INDUSTRY. BY ACCESSING THE SOFTWARE, YOU FURTHER ACKNOWLEDGE THAT YOUR HIGH-RISK USE OF THE SOFTWARE IS AT YOUR OWN RISK.
