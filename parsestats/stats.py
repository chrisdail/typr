# %% parse

import matplotlib.pyplot as plt
import pandas as pd
import re
import os
from pathlib import Path

from scipy.misc import face

# Ignore all apps unless they are in this whitelist
APPS_TO_KEEP = set([
    "Code",
    "Evernote",
    "Google Chrome",
    "Microsoft Outlook",
    "Microsoft Word",
    "Microsoft Powerpoint",
    "Slack",
    "IntelliJ IDEA",
    "Typora",
    "Obsidian"
])

start_block_re =re.compile("Totals for (.*): (\d+) {")
property_re = re.compile("\s*(.*) = (\d+);")

stats_file_path = os.path.join(Path.home(), "Documents", "TyprWordStats.log")


current_row = None
rows = []
with open(stats_file_path, "r") as f:
    for line in f.readlines():
        match = start_block_re.match(line)
        if match:

            if current_row:
                rows.append(current_row)

            current_row = {
                "date": match.group(1),
                "total": int(match.group(2))
            }
        elif "}" not in line:
            match = property_re.match(line)
            if match:
                app = match.group(1).removeprefix('"').removesuffix('"')
                if app in APPS_TO_KEEP:
                    current_row[app] = int(match.group(2))

df = pd.json_normalize(rows)
df["date"] = pd.to_datetime(df["date"], format="%B %d, %Y")

df_no_totals = df.drop(columns=["total"])

# %% Group by weeks

plt.figure(facecolor="white")
df.resample("M", on="date").mean().plot(figsize=(10,10))
plt.savefig("weekly-usage.png", facecolor="white")

# %% Yearly Usage

df_no_totals.resample("Y", on="date").mean().plot(kind="bar", stacked=True, figsize=(10,10))
plt.savefig("yearly-usage.png", facecolor="white")

# %%
