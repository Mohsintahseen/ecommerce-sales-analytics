# Power BI

| File | Purpose |
|---|---|
| `ecommerce_dashboard.pbix` | The four-page dashboard (open with Power BI Desktop) |
| `dax_measures.md` | Every measure and calculated column, with the MySQL result each was validated against |
| `ecommerce_theme.json`, `ecommerce_theme_v2.json` | Colour and font themes (v2 is the one used) |
| `background_1280x720.png` | Page background with the header band |

The dashboard reads from a local MySQL database named `ecommerce` (see `sql/`). The data is embedded in the file, so it opens and works without MySQL; **Refresh** only works if you rebuild the database first.
The embedded data is the cleaned, modified adaptation of the CC BY 4.0 dataset described in the main README.
