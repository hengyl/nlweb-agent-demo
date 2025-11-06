import asyncio
import nlweb_dataload
from pathlib import Path
from load_azd_env import load_azd_env

load_azd_env()

config_path = Path(__file__).parent / "config.yaml"
nlweb_dataload.init(config_path=str(config_path))

async def main():
    result = await nlweb_dataload.load_to_db(
        file_path="https://feeds.libsyn.com/121695/rss",
        site="Behind-the-Tech",
        file_type="rss",
        batch_size=50
    )
    print(f"Loaded {result['total_loaded']} documents")

asyncio.run(main())
