"""Write Finder view metadata on the mounted, writable release image."""
from pathlib import Path
import sys

from ds_store import DSStore
from mac_alias import Alias

volume = Path(sys.argv[1])
background = volume / ".background" / "background.png"
alias = Alias.for_file(str(background))
# Do not embed the packager's home/workspace path in public artifacts.
alias.volume.posix_path = b"/Volumes/" + alias.volume.name
with DSStore.open(str(volume / ".DS_Store"), "w+") as store:
    store["."]["bwsp"] = {
        "ShowStatusBar": False,
        "ShowToolbar": False,
        "ShowTabView": False,
        "ShowPathbar": False,
        "ShowSidebar": False,
        "ContainerShowSidebar": False,
        "WindowBounds": "{{180, 140}, {720, 440}}",
    }
    store["."]["icvp"] = {
        "viewOptionsVersion": 1,
        "backgroundType": 2,
        "backgroundImageAlias": alias.to_bytes(),
        "backgroundColorRed": 1.0,
        "backgroundColorGreen": 1.0,
        "backgroundColorBlue": 1.0,
        "iconSize": 128.0,
        "textSize": 14.0,
        "gridSpacing": 54.0,
        "gridOffsetX": 0.0,
        "gridOffsetY": 0.0,
        "scrollPositionX": 0.0,
        "scrollPositionY": 0.0,
        "labelOnBottom": True,
        "showIconPreview": False,
        "showItemInfo": False,
        "arrangeBy": "none",
    }
    store["."]["vSrn"] = ("long", 1)
    store["."]["icvl"] = ("type", b"icnv")
    store["ZRightClick.app"]["Iloc"] = (180, 225)
    store["Applications"]["Iloc"] = (540, 225)
