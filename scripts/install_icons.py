#!/usr/bin/env python3
"""Copy the attached tab/badge/home icons into the iOS asset catalog."""

from __future__ import annotations

import json
import shutil
from collections import deque
from pathlib import Path

from PIL import Image

SRC = Path("/Users/iremcelik/.cursor/projects/Users-iremcelik-ink-akademi-app-android-InkAcademy/assets")
DEST = Path("/Users/iremcelik/ink akademi app android/InkAcademy/ireminkakademi/Assets.xcassets")

TABS = {
    "TabHome": "IMG_1542-0f0775fd-9363-4fb1-9339-201f86bcff19.png",
    "TabModule": "IMG_1538-86d42f45-8199-43de-84aa-32f4ec0df062.png",
    "TabHomework": "IMG_1539-9d38f8a5-e217-4d4f-a621-eee928e46ae4.png",
    "TabShop": "IMG_1540-e3ab8c53-427b-492d-adb1-9a73a130f710.png",
    "TabAccount": "IMG_1541-8c7e4465-f574-4e80-ab3a-4542e6db668f.png",
}

COLOR = {
    1: "IMG_1543-41abcdfb-4606-407f-9a8e-a80bdd7f50f5.png",
    2: "IMG_1544-d46d1b70-52f8-4722-9ee7-839d395e58c2.png",
    3: "IMG_1545-735024f5-20c0-4362-b77f-41cd22ab8d15.png",
    4: "IMG_1546-e414a3e1-246e-4499-a099-1e9b43c5a8d8.png",
    5: "IMG_1547-3f21643b-7728-43ac-870d-6a7474504f87.png",
    6: "IMG_1548-0820d9ff-28ee-4c63-ab60-c1fdd93bbb41.png",
    7: "IMG_1549-cd84d565-bc0c-4c6b-9383-e488d62c5330.png",
    8: "IMG_1550-8bb4dd99-696f-4aef-803c-be6758fb65cc.png",
    9: "IMG_1563-64985b86-0ccc-4cc5-9dff-7700a4ca518d.png",
    10: "IMG_1551-9ef2610a-9217-4e20-a160-d27cfb7b1dc6.png",
    11: "IMG_1562-67b85549-e1e2-4817-b759-fb861cbf8673.png",
    12: "IMG_1561-f747e8ae-8740-4dbf-b99d-8cf551849feb.png",
    13: "IMG_1560-9da06044-56bd-4ed3-b416-f1a71d6b3571.png",
    14: "IMG_1558-e7d1f99c-5005-493c-8c65-16fb07b415b9.png",
    15: "IMG_1552-1c101e98-8ed1-4306-8f02-141993df0357.png",
    16: "IMG_1553-94ae894b-8e1e-445d-a4f3-872a1fface64.png",
    17: "IMG_1554-dba3e8b3-d197-45a3-9e53-a11c059909da.png",
    18: "IMG_1557-1a0b4027-b045-4b44-bdb7-1c5079b5b3d6.png",
    19: "IMG_1556-99e26fe3-49cf-4a45-903f-c58b8abe37af.png",
    20: "IMG_1555-8f4c44a0-8c59-4f28-b0d4-b431d3dcc6f4.png",
}

GRAY = {
    1: "IMG_1565-0618a6bb-e84e-46a3-ac5b-96a82514ce84.png",
    2: "IMG_1566-31ffc5b6-d8ae-454e-900c-9b81f44bb1fa.png",
    3: "IMG_1568-489f8797-00ba-4100-8159-29cd44958732.png",
    4: "IMG_1569-ec9a32dd-e02d-43d4-9829-46dc14e1543a.png",
    5: "IMG_1570-7ab53266-9419-4f9d-ba5d-ffcbdf10472e.png",
    6: "IMG_1548-bef3b07a-050b-474a-9980-3b4ec86dd798.png",
    7: "IMG_1571-33865429-94f6-4a7d-8c29-7ed8fed9a836.png",
    8: "IMG_1572-a78fc7d9-3a7c-41bf-82ee-5c1e49fdd881.png",
    9: "IMG_1573-111d2ed9-4119-4b74-9a49-f103d9604938.png",
    10: "IMG_1574-831dd38e-0a81-480c-bc1b-6b68fbaac0e3.png",
    11: "IMG_1575-9e303776-d6b7-48cd-8023-15bd2e45bc21.png",
    12: "IMG_1576-4b453009-e404-4ed0-abe0-69d775c91016.png",
    13: "IMG_1577-2a367a02-e248-4015-86e0-1e9dd4dc1e08.png",
    14: "IMG_1578-cd3d5d2d-7a81-4e69-94a0-9c3c0fbca80c.png",
    15: "IMG_1579-172a85cc-9253-4a79-829d-865f99143975.png",
    16: "IMG_1580-389ea0a7-e064-4477-b360-27eca2ce1adc.png",
    17: "IMG_1581-406ac298-2dae-4016-9021-48eac40578f3.png",
    18: "IMG_1582-2bb31285-3e37-4c57-84b1-d9671ecce808.png",
    19: "IMG_1583-f1bc3ea5-2df7-444b-803f-4f51f6225f77.png",
    20: "IMG_1584-54b5282c-52be-49a8-9272-8cbe51026b57.png",
}

HOME = {
    "HomeChatIcon": "IMG_1588-3870513d-7131-44b8-ac58-aa9677950fa4.png",
    "HomeGameIcon": "IMG_1564-a5e64d56-ad2c-4347-b422-fa58cb601ac0.png",
}


def write_imageset(folder: Path, filename: str, original: bool = True) -> None:
    folder.mkdir(parents=True, exist_ok=True)
    contents = {
        "images": [
            {"filename": filename, "idiom": "universal", "scale": "1x"},
            {"idiom": "universal", "scale": "2x"},
            {"idiom": "universal", "scale": "3x"},
        ],
        "info": {"author": "xcode", "version": 1},
    }
    if original:
        contents["properties"] = {"template-rendering-intent": "original"}
    (folder / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n")


def copy_png(src_name: str, dest: Path) -> None:
    src = SRC / src_name
    if not src.exists():
        raise FileNotFoundError(src)
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dest)


def knockout_edge_black(src: Path, dest: Path, threshold: int = 22) -> None:
    image = Image.open(src).convert("RGBA")
    pixels = image.load()
    width, height = image.size
    visited = bytearray(width * height)
    queue: deque[tuple[int, int]] = deque()
    for y in range(height):
        queue.append((0, y))
        queue.append((width - 1, y))
    for x in range(width):
        queue.append((x, 0))
        queue.append((x, height - 1))

    while queue:
        x, y = queue.popleft()
        if x < 0 or x >= width or y < 0 or y >= height:
            continue
        index = y * width + x
        if visited[index]:
            continue
        visited[index] = 1
        r, g, b, a = pixels[x, y]
        if a < 8 or (r < threshold and g < threshold and b < threshold):
            pixels[x, y] = (r, g, b, 0)
            queue.extend(((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)))

    dest.parent.mkdir(parents=True, exist_ok=True)
    image.save(dest)


def main() -> None:
    for tab, src in TABS.items():
        for state in ("Normal", "Selected"):
            name = f"{tab}{state}"
            folder = DEST / f"{name}.imageset"
            copy_png(src, folder / f"{name}.png")
            write_imageset(folder, f"{name}.png")

    for index, src in COLOR.items():
        name = f"BadgeHex{index:02d}"
        folder = DEST / f"{name}.imageset"
        copy_png(src, folder / f"{name}.png")
        write_imageset(folder, f"{name}.png")

    for index, src in GRAY.items():
        name = f"BadgeHex{index:02d}Gray"
        folder = DEST / f"{name}.imageset"
        copy_png(src, folder / f"{name}.png")
        write_imageset(folder, f"{name}.png")

    for name, src in HOME.items():
        folder = DEST / f"{name}.imageset"
        knockout_edge_black(SRC / src, folder / f"{name}.png")
        write_imageset(folder, f"{name}.png")

    print("icons installed")


if __name__ == "__main__":
    main()
