# Data Directory

Place your data files here for loading into the agent.

## Supported File Types

* **CSV files**: `.csv` format
* **RSS feeds**: Can be referenced by URL in config.yaml (no local file needed)
* Other formats supported by nlweb-dataload

## Usage

Add your data files to this directory, then reference them in `/config.yaml`:

```yaml
data_sources:
  - url: ./data/mydata.csv
    site_name: My-CSV-Data
    file_type: csv
    batch_size: 50
```

## Note

Large data files are automatically ignored by git (see `.gitignore`). Keep small sample files for testing in version control.
