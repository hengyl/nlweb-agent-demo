import asyncio
import nlweb_dataload
import yaml
from pathlib import Path
from load_azd_env import load_azd_env

load_azd_env()

# Use root-level config.yaml
config_path = Path(__file__).parent.parent.parent / "config.yaml"
nlweb_dataload.init(config_path=str(config_path))

# Load data sources from config
with open(config_path, 'r') as f:
    config = yaml.safe_load(f)

async def main():
    data_sources = config.get('data_sources', [])
    
    if not data_sources:
        print("No data sources configured in config.yaml")
        return
    
    total_documents = 0
    for source in data_sources:
        print(f"Loading from {source['url']} (site: {source['site_name']})...")
        result = await nlweb_dataload.load_to_db(
            file_path=source['url'],
            site=source['site_name'],
            file_type=source.get('file_type', 'rss'),
            batch_size=source.get('batch_size', 50)
        )
        loaded = result['total_loaded']
        print(f"Loaded {loaded} documents from {source['site_name']}")
        total_documents += loaded
    
    print(f"\nTotal loaded: {total_documents} documents")

asyncio.run(main())
