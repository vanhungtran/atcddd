# Reply to Laura de Jong

Hi Laura,

No worries at all — Laura is a perfectly clear first name to me! And
thank you for the kind words, I’m glad atcddd looks useful for your
clinical trials work.

You’re exactly right about `get_atc_data("N02BA01")` — it queries the
WHO ATC/DDD index website and retrieves the classification info and DDD
data for that code.

And here’s the good news: **what you’re asking for already exists in the
package!** You don’t need a separate `get_atc_code()` function because
there are several functions that go from drug *name* → ATC code:

- **`resolve_atc("aspirin")`** — the main one. Give it a drug name, get
  back the ATC code, official WHO name, and DDD information. It works
  fully offline against the cached WHO database, so it’s instant and
  needs no internet. It also knows common brand names (e.g., “lipitor” →
  atorvastatin, “tylenol” → paracetamol).

- **`resolve_batch(c("aspirin", "metformin", "ibuprofen"))`** — same
  thing but for a whole vector of drug names at once, perfect when you
  have a column of medications to code.

- **`search_drug("statin")`** — more exploratory: searches drug names by
  substring and returns all matches, ranked by quality.

- **`fuzzy_match_drug("asprin")`** — handles typos and misspellings
  using edit distance (so “acetominophen” still finds paracetamol).

So in practice:

``` r

library(atcddd)
resolve_atc("aspirin")
#> ATC: N02BA01 · acetylsalicylic acid · DDD: 3 g (Oral)
```

There’s also
[`atc_add_synonym()`](https://vanhungtran.github.io/atcddd/reference/atc_add_synonym.md)
if you have study-specific brand names you want to register so they
resolve correctly. And for getting ATC codes from free-text clinical
notes, there’s
[`atc_from_text()`](https://vanhungtran.github.io/atcddd/reference/atc_from_text.md).

Hope that helps! And please don’t hesitate to email or open a GitHub
issue if you run into anything — no GitHub expertise needed, a quick
email works just as well.

Cheers, Huynh
