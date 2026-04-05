"""Temporary script: print titles of 5 AI-related works from OpenAlex via pyalex."""

from pyalex import Works

results = Works().search("artificial intelligence").get(per_page=5)

for i, work in enumerate(results, 1):
    title = work.get("display_name") or work.get("title") or "(no title)"
    print(f"{i}. {title}")
