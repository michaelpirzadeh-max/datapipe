"""Apply paper_dashboard_schema.sql to Neon (idempotent: IF NOT EXISTS)."""

from __future__ import annotations

from pathlib import Path

from db_config import connect

_SCHEMA = Path(__file__).resolve().parent / "paper_dashboard_schema.sql"


def _sql_statements(sql_text: str) -> list[str]:
    lines = []
    for line in sql_text.splitlines():
        stripped = line.strip()
        if stripped.startswith("--") or not stripped:
            continue
        lines.append(line)
    text = "\n".join(lines)
    return [s.strip() for s in text.split(";") if s.strip()]


def ensure_papers_table(*, quiet: bool = False) -> int:
    """Run paper_dashboard_schema.sql. Returns number of SQL statements executed."""
    sql = _SCHEMA.read_text(encoding="utf-8")
    stmts = _sql_statements(sql)
    with connect() as conn:
        conn.autocommit = True
        with conn.cursor() as cur:
            for stmt in stmts:
                cur.execute(stmt)
    if not quiet:
        print(f"Applied {_SCHEMA.name}: {len(stmts)} statement(s). Table papers is ready.")
    return len(stmts)


def main() -> None:
    ensure_papers_table(quiet=False)


if __name__ == "__main__":
    main()
