# Bottleo WCL Check

Bottleo WCL Check is a lightweight World of Warcraft addon that adds a small **WCL** button to LFG applicant rows.

Clicking the button shows a copyable Warcraft Logs character URL for that applicant, making it quicker to check logs while forming a group.

## Features

- Adds a **WCL** button to Group Finder / LFG applicant rows
- Generates Warcraft Logs character profile links
- Adds `?zone=47` to the generated URL for the current Mythic+ season
- Shows the URL in a highlighted copy box for easy `Ctrl + C`
- Lightweight addon with no external dependencies
- Does not make web or API requests from inside World of Warcraft

## Example URL

```text
https://www.warcraftlogs.com/character/us/frostmourne/CharacterName?zone=47
Installation
Download the addon.
Extract the folder into your World of Warcraft Retail addons folder:
World of Warcraft/_retail_/Interface/AddOns/
The final folder should look like this:
Interface/AddOns/Bottleo_WCLcheck/
Restart World of Warcraft or type:
/reload
Open the AddOns menu and make sure Bottleo WCL Check is enabled.
Usage

List a group in LFG and wait for applicants.

A small WCL button should appear on each applicant row. Clicking the button opens a copyable Warcraft Logs URL for that applicant.

You can also manually test the popup with:

/bwcl Character-Realm

Example:

/bwcl Redthistle-Frostmourne

You can manually refresh the LFG applicant buttons with:

/wclcheck
Notes

This addon does not pull DPS, parse, ranking, or combat log data directly from Warcraft Logs.

World of Warcraft addons cannot make normal web/API requests from inside the game client, so this addon only generates a copyable Warcraft Logs URL.

Disclaimer

This addon is not affiliated with, endorsed by, or sponsored by Warcraft Logs.

Warcraft Logs is a third-party service operated separately from this addon.
