"""
Fetch recent AI research works from OpenAlex: resolve the Artificial Intelligence
concept, filter works from the last 3 calendar days (inclusive), and save full
records to a timestamped JSON file under temp/.
"""

from __future__ import annotations

import json
import os
import warnings
from datetime import date, datetime, timedelta, timezone
from pathlib import Path

import pyalex
from pyalex import Concepts, Works

# OpenAlex recommends setting an email for the "polite pool" (higher rate limits).
if addr := os.environ.get("OPENALEX_EMAIL"):
    pyalex.config.email = addr

# Search string (correct spelling; OpenAlex matches concepts by relevance).
CONCEPT_SEARCH_QUERY = "Artificial Intelligence"


def last_three_calendar_days() -> tuple[date, date]:
    """Return (from_date, to_date) covering today and the two previous days."""
    to_date = date.today()
    from_date = to_date - timedelta(days=2)
    return from_date, to_date


def main() -> None:
    from_date, to_date = last_three_calendar_days()

    # 1–2. Search concepts and take the top match (Concepts API is deprecated by
    # OpenAlex in favor of topics; we still follow the requested steps).
    with warnings.catch_warnings():
        warnings.simplefilter("ignore", DeprecationWarning)
        concept_page = Concepts().search(CONCEPT_SEARCH_QUERY).get(per_page=1)
    if not concept_page:
        raise RuntimeError(f"No concepts found for search: {CONCEPT_SEARCH_QUERY!r}")
    concept = dict(concept_page[0])
    concept_short_id = concept["id"].rsplit("/", 1)[-1]

    # 3. Filter works: concept + publication date range (inclusive).
    works_query = Works().filter(
        concepts={"id": concept_short_id},
        from_publication_date=from_date.isoformat(),
        to_publication_date=to_date.isoformat(),
    )

    # 4. Collect all works (default API response includes full work objects).
    works: list[dict] = []
    response_meta = None
    for batch in works_query.paginate(per_page=200, n_max=None):
        if response_meta is None:
            response_meta = batch.meta
        works.extend(dict(w) for w in batch)

    out_dir = Path(__file__).resolve().parent / "temp"
    out_dir.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    out_path = out_dir / f"ai_works_{stamp}.json"

    payload = {
        "fetched_at_utc": datetime.now(timezone.utc).isoformat(),
        "query": {
            "concept_search": CONCEPT_SEARCH_QUERY,
            "concept": concept,
            "from_publication_date": from_date.isoformat(),
            "to_publication_date": to_date.isoformat(),
        },
        "openalex_meta": response_meta,
        "works": works,
    }

    out_path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(f"Wrote {len(works)} works to {out_path}")


if __name__ == "__main__":
    main()
