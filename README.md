# nbk_autoblacklist
NBK AutoBlacklist is a companion add-on for NerzorsBlacklistKeeper. It detects boosting and paid leveling ads by combining signals such as an offer, the service being sold, and a price or contact phrase. It can also detect repeated messages from the same sender.

Start in observation mode by opening `/nbk config`, choosing **AutoBlacklist**, and selecting **Enable sender diagnostics**. Auto-Hide is off by default. Use `/nbkauto` to inspect the latest message examined by the add-on, or `/nbkauto hits` to see the last ten matches.

When you enable **Auto-Hide**, the first clear ad in an enabled public channel is hidden. A second clear ad from the same sender within ten minutes adds a local sender block. Later messages from that sender are hidden in enabled channels even if the wording changes. Use **Unblock** in **Local sender rules** to let the sender through again and create a local exception. Trade (Services), whispers, group chat, and guild chat each have their own controls.

**Detection languages** include English (`enUS`, `enGB`), German, Russian, Simplified and Traditional Chinese, Korean, French, Spanish (`esES`, `esMX`), Brazilian Portuguese, and Italian. Choose the detection packs independently of the settings language. English and German are enabled by default.

**Tested with NBK 2.2.0** on WoW: Forever 1.60.1 and WoW Retail 12.1.5, including with NBK ChatFilters enabled. Install NBK as a required dependency. [NerzorsBlacklistKeeper on CurseForge](https://www.curseforge.com/wow/addons/nerzorsblacklistkeeper)
