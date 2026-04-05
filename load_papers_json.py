"""
Load OpenAlex-style works from a JSON file into Postgres `papers`.

- Path: dump like fetch_recent_ai_papers_openalex.py output (`{ "works": [...] }`),
  a bare list of works, or a single work object.
- Ensures schema via create_papers_table.ensure_papers_table().
- Deduplicates: same `openalex_id` in the file keeps the last row; DB uses upsert
  (ON CONFLICT DO UPDATE) so re-runs refresh existing rows.
"""

from __future__ import annotations

import argparse
import json
from collections import OrderedDict
from datetime import date
from pathlib import Path
from typing import Any

from create_papers_table import ensure_papers_table
from db_config import connect


def _openalex_tail(url: str | None) -> str | None:
    if not url or not isinstance(url, str):
        return None
    return url.rsplit("/", 1)[-1] or None


def _display_name(node: Any) -> str | None:
    if isinstance(node, dict):
        return node.get("display_name")
    return None


def work_to_row(work: dict[str, Any]) -> dict[str, Any] | None:
    """Map one OpenAlex work JSON object to columns for `papers`. Skip invalid."""
    oid = _openalex_tail(work.get("id"))
    if not oid:
        return None
    title = (work.get("title") or work.get("display_name") or "").strip()
    if not title:
        title = "(untitled)"

    pub_date: date | None = None
    raw_pd = work.get("publication_date")
    if isinstance(raw_pd, str) and raw_pd.strip():
        try:
            pub_date = date.fromisoformat(raw_pd.strip()[:10])
        except ValueError:
            pub_date = None

    cn = work.get("citation_normalized_percentile")
    if not isinstance(cn, dict):
        cn = {}

    oa = work.get("open_access")
    if not isinstance(oa, dict):
        oa = {}

    pl = work.get("primary_location")
    if not isinstance(pl, dict):
        pl = {}
    src = pl.get("source")
    if not isinstance(src, dict):
        src = {}

    pt = work.get("primary_topic")
    if not isinstance(pt, dict):
        pt = {}

    sub = pt.get("subfield")
    fld = pt.get("field")
    dom = pt.get("domain")

    indexed = work.get("indexed_in")
    if indexed is not None and not isinstance(indexed, list):
        indexed = None

    authorships = work.get("authorships")
    author_count = len(authorships) if isinstance(authorships, list) else None

    return {
        "openalex_id": oid,
        "doi": work.get("doi"),
        "title": title,
        "publication_date": pub_date,
        "publication_year": work.get("publication_year"),
        "work_type": work.get("type"),
        "language": work.get("language"),
        "cited_by_count": int(work.get("cited_by_count") or 0),
        "fwci": work.get("fwci"),
        "citation_percentile": cn.get("value"),
        "is_top_1_percent_cited": cn.get("is_in_top_1_percent"),
        "is_top_10_percent_cited": cn.get("is_in_top_10_percent"),
        "author_count": author_count,
        "referenced_works_count": work.get("referenced_works_count"),
        "institutions_distinct_count": work.get("institutions_distinct_count"),
        "countries_distinct_count": work.get("countries_distinct_count"),
        "locations_count": work.get("locations_count"),
        "is_oa": oa.get("is_oa"),
        "oa_status": oa.get("oa_status"),
        "is_retracted": work.get("is_retracted"),
        "is_paratext": work.get("is_paratext"),
        "venue_openalex_id": _openalex_tail(src.get("id")),
        "venue_name": src.get("display_name"),
        "venue_type": src.get("type"),
        "publisher_name": src.get("host_organization_name"),
        "issn_l": src.get("issn_l"),
        "landing_page_url": pl.get("landing_page_url"),
        "pdf_url": pl.get("pdf_url"),
        "primary_topic_id": _openalex_tail(pt.get("id")),
        "primary_topic_name": pt.get("display_name"),
        "topic_subfield_name": _display_name(sub),
        "topic_field_name": _display_name(fld),
        "topic_domain_name": _display_name(dom),
        "primary_topic_score": pt.get("score"),
        "indexed_in": indexed,
    }


def _parse_works_payload(payload: Any) -> list[dict[str, Any]]:
    if isinstance(payload, list):
        return [w for w in payload if isinstance(w, dict)]
    if isinstance(payload, dict):
        if "works" in payload:
            raw = payload["works"]
            if isinstance(raw, list):
                return [w for w in raw if isinstance(w, dict)]
            raise ValueError("JSON 'works' must be a list")
        if payload.get("id") and isinstance(payload.get("id"), str) and "openalex.org" in payload["id"]:
            return [payload]
    raise ValueError("JSON must be a list of works, { 'works': [...] }, or one work object")


def _dedupe_works(works: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Later rows win (OrderedDict by openalex_id)."""
    by_id: OrderedDict[str, dict[str, Any]] = OrderedDict()
    for w in works:
        tail = _openalex_tail(w.get("id"))
        if tail:
            by_id[tail] = w
    return list(by_id.values())


UPSERT_SQL = """
INSERT INTO papers (
    openalex_id, doi, title, publication_date, publication_year, work_type, language,
    cited_by_count, fwci, citation_percentile, is_top_1_percent_cited, is_top_10_percent_cited,
    author_count, referenced_works_count, institutions_distinct_count, countries_distinct_count,
    locations_count, is_oa, oa_status, is_retracted, is_paratext,
    venue_openalex_id, venue_name, venue_type, publisher_name, issn_l, landing_page_url, pdf_url,
    primary_topic_id, primary_topic_name, topic_subfield_name, topic_field_name, topic_domain_name,
    primary_topic_score, indexed_in
) VALUES (
    %(openalex_id)s, %(doi)s, %(title)s, %(publication_date)s, %(publication_year)s,
    %(work_type)s, %(language)s, %(cited_by_count)s, %(fwci)s, %(citation_percentile)s,
    %(is_top_1_percent_cited)s, %(is_top_10_percent_cited)s, %(author_count)s,
    %(referenced_works_count)s, %(institutions_distinct_count)s, %(countries_distinct_count)s,
    %(locations_count)s, %(is_oa)s, %(oa_status)s, %(is_retracted)s, %(is_paratext)s,
    %(venue_openalex_id)s, %(venue_name)s, %(venue_type)s, %(publisher_name)s, %(issn_l)s,
    %(landing_page_url)s, %(pdf_url)s, %(primary_topic_id)s, %(primary_topic_name)s,
    %(topic_subfield_name)s, %(topic_field_name)s, %(topic_domain_name)s, %(primary_topic_score)s,
    %(indexed_in)s
)
ON CONFLICT (openalex_id) DO UPDATE SET
    doi = EXCLUDED.doi,
    title = EXCLUDED.title,
    publication_date = EXCLUDED.publication_date,
    publication_year = EXCLUDED.publication_year,
    work_type = EXCLUDED.work_type,
    language = EXCLUDED.language,
    cited_by_count = EXCLUDED.cited_by_count,
    fwci = EXCLUDED.fwci,
    citation_percentile = EXCLUDED.citation_percentile,
    is_top_1_percent_cited = EXCLUDED.is_top_1_percent_cited,
    is_top_10_percent_cited = EXCLUDED.is_top_10_percent_cited,
    author_count = EXCLUDED.author_count,
    referenced_works_count = EXCLUDED.referenced_works_count,
    institutions_distinct_count = EXCLUDED.institutions_distinct_count,
    countries_distinct_count = EXCLUDED.countries_distinct_count,
    locations_count = EXCLUDED.locations_count,
    is_oa = EXCLUDED.is_oa,
    oa_status = EXCLUDED.oa_status,
    is_retracted = EXCLUDED.is_retracted,
    is_paratext = EXCLUDED.is_paratext,
    venue_openalex_id = EXCLUDED.venue_openalex_id,
    venue_name = EXCLUDED.venue_name,
    venue_type = EXCLUDED.venue_type,
    publisher_name = EXCLUDED.publisher_name,
    issn_l = EXCLUDED.issn_l,
    landing_page_url = EXCLUDED.landing_page_url,
    pdf_url = EXCLUDED.pdf_url,
    primary_topic_id = EXCLUDED.primary_topic_id,
    primary_topic_name = EXCLUDED.primary_topic_name,
    topic_subfield_name = EXCLUDED.topic_subfield_name,
    topic_field_name = EXCLUDED.topic_field_name,
    topic_domain_name = EXCLUDED.topic_domain_name,
    primary_topic_score = EXCLUDED.primary_topic_score,
    indexed_in = EXCLUDED.indexed_in
"""


def load_json_path(path: Path, *, batch_size: int = 500) -> tuple[int, int]:
    """
    Ensure table, load works from JSON. Returns (rows_upsert_attempted, rows_skipped_no_id).
    """
    payload = json.loads(path.read_text(encoding="utf-8"))
    works = _dedupe_works(_parse_works_payload(payload))

    rows: list[dict[str, Any]] = []
    skipped = 0
    for w in works:
        row = work_to_row(w)
        if row is None:
            skipped += 1
            continue
        rows.append(row)

    ensure_papers_table(quiet=True)

    with connect() as conn:
        with conn.cursor() as cur:
            for i in range(0, len(rows), batch_size):
                chunk = rows[i : i + batch_size]
                cur.executemany(UPSERT_SQL, chunk)
        conn.commit()

    return len(rows), skipped


def main() -> None:
    p = argparse.ArgumentParser(description="Load OpenAlex works JSON into papers table.")
    p.add_argument(
        "json_path",
        type=Path,
        help="Path to JSON ({works: [...]}, list of works, or one work)",
    )
    p.add_argument(
        "--batch-size",
        type=int,
        default=500,
        help="Rows per executemany batch (default 500)",
    )
    args = p.parse_args()
    path = args.json_path.expanduser().resolve()
    if not path.is_file():
        raise SystemExit(f"File not found: {path}")

    inserted, skipped = load_json_path(path, batch_size=args.batch_size)
    print(f"Upserted {inserted} paper row(s) from {path.name}; skipped {skipped} (no openalex id).")


if __name__ == "__main__":
    main()
