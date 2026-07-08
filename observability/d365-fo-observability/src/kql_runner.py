from __future__ import annotations

from datetime import timedelta
from pathlib import Path
import os
from typing import Any

import pandas as pd
from dotenv import load_dotenv
from azure.core.exceptions import HttpResponseError
from azure.identity import (
    AzureCliCredential,
    ChainedTokenCredential,
    ClientSecretCredential,
    DeviceCodeCredential,
)
from azure.monitor.query import LogsQueryClient, LogsQueryStatus

try:
    import matplotlib.pyplot as plt
except ModuleNotFoundError:
    plt = None


ANALYST_THEME = {
    "figure.facecolor": "#f8f6f1",
    "axes.facecolor": "#fffdf8",
    "axes.edgecolor": "#d8d2c4",
    "axes.labelcolor": "#2f3b33",
    "axes.titlecolor": "#1f2a24",
    "axes.grid": True,
    "grid.color": "#ddd6c8",
    "grid.alpha": 0.6,
    "grid.linestyle": "--",
    "xtick.color": "#435246",
    "ytick.color": "#435246",
}

ANALYST_PALETTE = [
    "#2f6f5e",
    "#d97b2d",
    "#7b8f3a",
    "#5f6db0",
    "#b84f5f",
    "#8b6f47",
]


def _project_root() -> Path:
    root = Path(__file__).resolve().parents[1]
    return root


def load_config() -> dict[str, Any]:
    root = _project_root()
    load_dotenv(root / ".env")

    workspace_id = os.getenv("LAW_WORKSPACE_ID", "").strip()
    appinsights_resource_id = os.getenv("APPINSIGHTS_RESOURCE_ID", "").strip()
    appinsights_connection_string = os.getenv("APPINSIGHTS_CONNECTION_STRING", "").strip()
    query_days = int(os.getenv("QUERY_DAYS", "7"))
    tenant_id = os.getenv("AZURE_TENANT_ID", "").strip()
    client_id = os.getenv("AZURE_CLIENT_ID", "").strip()
    client_secret = os.getenv("AZURE_CLIENT_SECRET", "").strip()
    client_name = os.getenv("CLIENT_NAME", "").strip()
    queries_dir = root / "queries"
    exports_dir = root / "exports"
    exports_dir.mkdir(exist_ok=True)

    if not workspace_id and not appinsights_resource_id:
        raise ValueError("Falta LAW_WORKSPACE_ID o APPINSIGHTS_RESOURCE_ID en .env")

    return {
        "root": root,
        "workspace_id": workspace_id,
        "appinsights_resource_id": appinsights_resource_id,
        "appinsights_connection_string": appinsights_connection_string,
        "query_days": query_days,
        "tenant_id": tenant_id,
        "client_id": client_id,
        "client_secret": client_secret,
        "client_name": client_name,
        "queries_dir": queries_dir,
        "exports_dir": exports_dir,
    }


def get_auth_mode(config: dict[str, Any] | None = None, prefer_cli: bool = False) -> str:
    cfg = config or load_config()

    if prefer_cli:
        return "Azure CLI"

    if cfg["client_id"] and cfg["client_secret"] and cfg["tenant_id"]:
        return "Service Principal (tenant explicito)"

    if cfg["client_id"] and cfg["client_secret"]:
        return "Azure CLI / Device Code (SP incompleto: falta AZURE_TENANT_ID)"

    return "Azure CLI / Device Code (autodetect/delegado)"


def build_client(
    prefer_cli: bool = False,
    config: dict[str, Any] | None = None,
) -> LogsQueryClient:
    cfg = config or load_config()

    if prefer_cli:
        return LogsQueryClient(AzureCliCredential())

    if cfg["client_id"] and cfg["client_secret"] and cfg["tenant_id"]:
        credential = ClientSecretCredential(
            tenant_id=cfg["tenant_id"],
            client_id=cfg["client_id"],
            client_secret=cfg["client_secret"],
        )
        return LogsQueryClient(credential)

    credential = ChainedTokenCredential(
        AzureCliCredential(),
        DeviceCodeCredential(),
    )
    return LogsQueryClient(credential)


def load_kql(file_name: str) -> str:
    cfg = load_config()
    path = cfg["queries_dir"] / file_name
    if not path.exists():
        raise FileNotFoundError(f"No existe el archivo KQL: {path}")
    return path.read_text(encoding="utf-8")


def validate_target_access(
    client: LogsQueryClient,
    config: dict[str, Any] | None = None,
) -> bool:
    cfg = config or load_config()
    test_query = "print x=1"

    try:
        if cfg["appinsights_resource_id"]:
            response = client.query_resource(
                resource_id=cfg["appinsights_resource_id"],
                query=test_query,
                timespan=timedelta(days=1),
                server_timeout=30,
            )
            target_name = "resource_id"
        else:
            response = client.query_workspace(
                workspace_id=cfg["workspace_id"],
                query=test_query,
                timespan=timedelta(days=1),
                server_timeout=30,
            )
            target_name = "workspace_id"

        if response.status == LogsQueryStatus.SUCCESS:
            print(f"Target accesible ({target_name}) y autenticacion OK")
            return True

        print("Target responde parcialmente")
        print(response.partial_error)
        return True
    except HttpResponseError as err:
        err_text = str(err)
        if "WorkspaceNotFoundError" in err_text:
            print("Workspace no encontrado. Revisa LAW_WORKSPACE_ID en .env")
        elif "PathNotFoundError" in err_text or "ResourceNotFound" in err_text:
            print("Resource ID no encontrado. Revisa APPINSIGHTS_RESOURCE_ID en .env")
        elif "AuthorizationFailed" in err_text or "Forbidden" in err_text:
            print("Sin permisos sobre el target. Solicita rol de lectura")
        else:
            print("Error validando target:")
            print(err_text)
        return False
    except Exception as err:
        print("Error de autenticacion o entorno:")
        print(err)
        return False


def run_kql(
    client: LogsQueryClient,
    query: str,
    days: int | None = None,
    name: str | None = None,
    config: dict[str, Any] | None = None,
) -> pd.DataFrame:
    cfg = config or load_config()
    query_days = days if days is not None else cfg["query_days"]

    try:
        if name:
            print(f"Ejecutando: {name}")

        if cfg["appinsights_resource_id"]:
            response = client.query_resource(
                resource_id=cfg["appinsights_resource_id"],
                query=query,
                timespan=timedelta(days=query_days),
                server_timeout=600,
            )
        else:
            response = client.query_workspace(
                workspace_id=cfg["workspace_id"],
                query=query,
                timespan=timedelta(days=query_days),
                server_timeout=600,
            )

        if response.status == LogsQueryStatus.SUCCESS:
            tables = response.tables
        else:
            print("Consulta con resultado parcial")
            print(response.partial_error)
            tables = response.partial_data

        if not tables:
            return pd.DataFrame()

        table = tables[0]
        df = pd.DataFrame(data=table.rows, columns=table.columns)
        print(f"Filas devueltas: {len(df)}")
        return df

    except HttpResponseError as err:
        print("Error ejecutando KQL")
        print(err)
        return pd.DataFrame()


def prepare_for_excel(df: pd.DataFrame) -> pd.DataFrame:
    out = df.copy()
    for col in out.columns:
        if isinstance(out[col].dtype, pd.DatetimeTZDtype):
            out[col] = out[col].dt.tz_convert("UTC").dt.tz_localize(None)
    return out


def export_results_to_excel(results: dict[str, pd.DataFrame], output_path: Path) -> None:
    with pd.ExcelWriter(output_path, engine="openpyxl") as writer:
        for sheet_name, df in results.items():
            safe_df = prepare_for_excel(df)
            safe_df.to_excel(writer, sheet_name=sheet_name[:31], index=False)


def set_analyst_theme() -> None:
    if plt is None:
        return
    plt.style.use("default")
    plt.rcParams.update(ANALYST_THEME)


def metric_snapshot(metrics: dict[str, Any], value_column: str = "Valor") -> pd.DataFrame:
    snapshot = pd.DataFrame(
        [{"Metrica": key, value_column: value} for key, value in metrics.items()]
    )
    return snapshot


def summarize_top_items(
    df: pd.DataFrame,
    label_col: str,
    value_col: str,
    top_n: int = 5,
    ascending: bool = False,
) -> pd.DataFrame:
    if df.empty or label_col not in df.columns or value_col not in df.columns:
        return pd.DataFrame(columns=[label_col, value_col])

    summary = df[[label_col, value_col]].copy().dropna()
    summary[value_col] = pd.to_numeric(summary[value_col], errors="coerce")
    summary = summary.dropna(subset=[value_col])
    return summary.sort_values(value_col, ascending=ascending).head(top_n).reset_index(drop=True)


def plot_bar(
    df: pd.DataFrame,
    category_col: str,
    value_col: str,
    title: str,
    top_n: int = 15,
    ascending: bool = False,
    figsize: tuple[int, int] = (12, 6),
) -> None:
    if plt is None:
        print("matplotlib no esta instalado en este entorno. Ejecuta el notebook con el kernel configurado o instala matplotlib.")
        return

    if df.empty or category_col not in df.columns or value_col not in df.columns:
        print("No hay datos suficientes para dibujar el grafico.")
        return

    set_analyst_theme()

    chart_df = df[[category_col, value_col]].copy().dropna()
    chart_df[value_col] = pd.to_numeric(chart_df[value_col], errors="coerce")
    chart_df = chart_df.dropna(subset=[value_col])
    chart_df = chart_df.sort_values(value_col, ascending=ascending).head(top_n)

    plt.figure(figsize=figsize)
    plt.barh(
        chart_df[category_col].astype(str),
        chart_df[value_col],
        color=ANALYST_PALETTE[0],
    )
    plt.title(title)
    plt.xlabel(value_col)
    plt.ylabel(category_col)
    plt.gca().invert_yaxis()
    plt.tight_layout()
    plt.show()


def plot_timeseries(
    df: pd.DataFrame,
    time_col: str,
    value_cols: list[str],
    title: str,
    figsize: tuple[int, int] = (12, 6),
) -> None:
    if plt is None:
        print("matplotlib no esta instalado en este entorno. Ejecuta el notebook con el kernel configurado o instala matplotlib.")
        return

    if df.empty or time_col not in df.columns:
        print("No hay datos suficientes para dibujar la serie temporal.")
        return

    set_analyst_theme()

    chart_df = df.copy()
    chart_df[time_col] = pd.to_datetime(chart_df[time_col], errors="coerce")
    chart_df = chart_df.dropna(subset=[time_col]).sort_values(time_col)

    available_cols = [col for col in value_cols if col in chart_df.columns]
    if not available_cols:
        print("No hay columnas numericas disponibles para la serie temporal.")
        return

    plt.figure(figsize=figsize)
    for index, col in enumerate(available_cols):
        series = pd.to_numeric(chart_df[col], errors="coerce")
        plt.plot(
            chart_df[time_col],
            series,
            marker="o",
            label=col,
            color=ANALYST_PALETTE[index % len(ANALYST_PALETTE)],
            linewidth=2,
        )

    plt.title(title)
    plt.xlabel(time_col)
    plt.ylabel("Valor")
    plt.legend()
    plt.xticks(rotation=45)
    plt.tight_layout()
    plt.show()
