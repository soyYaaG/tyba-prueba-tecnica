import tomllib
from pathlib import Path

from pydantic import BaseModel

__BASE_DIR = Path(__file__).resolve().parent.parent.parent


class DatabaseConfig(BaseModel):
    path: Path


class MigrationsConfig(BaseModel):
    directory: Path


class DataConfig(BaseModel):
    raw_directory: Path
    output_directory: Path


class SnapshotConfig(BaseModel):
    batch: str
    file: str


class PipelineConfig(BaseModel):
    snapshots: list[SnapshotConfig]
    fail_on_empty: bool = True


class AppConfig(BaseModel):
    database: DatabaseConfig
    migrations: MigrationsConfig
    data: DataConfig
    pipeline: PipelineConfig


def __load_config() -> AppConfig:
    config_path = __BASE_DIR / 'config' / 'settings.toml'

    with config_path.open('rb') as file:
        raw_config = tomllib.load(file)

    return AppConfig.model_validate(raw_config)


config = __load_config()
