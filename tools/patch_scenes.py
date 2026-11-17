"""Swaps the placeholder ColorRect visuals in the character scenes for
generated sprite art with a soft ground shadow."""

import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

SHADOW = "res://assets/sprites/fx/shadow.png"
BOB = "res://scripts/fx/idle_bob.gd"

# scene file -> (texture, scale, shadow scale, bob amplitude)
SCENES = {
    "scenes/player/player.tscn": ("res://assets/sprites/heroes/hexblade.png", 0.34, 0.55, 1.6),
    "scenes/player/hexblade.tscn": ("res://assets/sprites/heroes/hexblade.png", 0.34, 0.55, 1.6),
    "scenes/player/ironclad.tscn": ("res://assets/sprites/heroes/ironclad.png", 0.34, 0.55, 1.6),
    "scenes/player/wraithborn.tscn": ("res://assets/sprites/heroes/wraithborn.png", 0.34, 0.55, 1.6),
    "scenes/player/stormcaller.tscn": ("res://assets/sprites/heroes/stormcaller.png", 0.34, 0.55, 1.6),
    "scenes/enemies/shambling_corpse.tscn": ("res://assets/sprites/enemies/shambling_corpse.png", 0.32, 0.42, 1.8),
    "scenes/enemies/bat_swarm.tscn": ("res://assets/sprites/enemies/bat_swarm.png", 0.26, 0.30, 2.6),
    "scenes/enemies/armored_knight.tscn": ("res://assets/sprites/enemies/armored_knight.png", 0.40, 0.50, 1.4),
    "scenes/enemies/ghost.tscn": ("res://assets/sprites/enemies/ghost.png", 0.34, 0.44, 2.4),
    "scenes/enemies/exploding_imp.tscn": ("res://assets/sprites/enemies/exploding_imp.png", 0.30, 0.38, 2.0),
    "scenes/enemies/necromancer.tscn": ("res://assets/sprites/enemies/necromancer.png", 0.36, 0.46, 1.4),
    "scenes/enemies/shadow_drake.tscn": ("res://assets/sprites/enemies/shadow_drake.png", 0.44, 0.52, 2.2),
    "scenes/enemies/giant_troll.tscn": ("res://assets/sprites/enemies/giant_troll.png", 0.68, 0.95, 1.2),
    "scenes/enemies/lich_king.tscn": ("res://assets/sprites/enemies/lich_king.png", 0.70, 0.80, 1.6),
}


def patch(path, texture, scale, shadow_scale, bob_amt):
    full = os.path.join(ROOT, path)
    with open(full, encoding="utf-8") as fh:
        text = fh.read()

    # Which visual node name does this scene use?
    node_name = "Sprite2D" if "name=\"Sprite2D\" type=\"ColorRect\"" in text else "Visual"
    pattern = re.compile(
        r'\[node name="%s" type="ColorRect" parent="\."\]\n(?:[^\[]*)' % re.escape(node_name)
    )
    m = pattern.search(text)
    if not m:
        print("SKIP (no color rect):", path)
        return

    sprite_id = "tex_art"
    shadow_id = "tex_shadow"
    bob_id = "script_bob"
    header_extra = (
        f'[ext_resource type="Texture2D" path="{texture}" id="{sprite_id}"]\n'
        f'[ext_resource type="Texture2D" path="{SHADOW}" id="{shadow_id}"]\n'
        f'[ext_resource type="Script" path="{BOB}" id="{bob_id}"]\n'
    )
    body = (
        f'[node name="{node_name}" type="Sprite2D" parent="."]\n'
        f'texture = ExtResource("{sprite_id}")\n'
        f'scale = Vector2({scale}, {scale})\n'
        f'script = ExtResource("{bob_id}")\n'
        f'bob_amplitude = {bob_amt}\n'
        f'\n'
        f'[node name="Shadow" type="Sprite2D" parent="."]\n'
        f'z_index = -1\n'
        f'position = Vector2(0, 14)\n'
        f'texture = ExtResource("{shadow_id}")\n'
        f'scale = Vector2({shadow_scale}, {shadow_scale * 0.85})\n'
        f'modulate = Color(1, 1, 1, 0.7)\n'
        f'\n'
    )
    text = text[:m.start()] + body + text[m.end():]

    # Insert new ext resources before the first [sub_resource] or first [node].
    insert_at = text.find("\n[sub_resource")
    if insert_at < 0:
        insert_at = text.find("\n[node")
    text = text[:insert_at + 1] + header_extra + text[insert_at + 1:]

    # Recompute load_steps.
    ext = len(re.findall(r"^\[ext_resource", text, re.M))
    sub = len(re.findall(r"^\[sub_resource", text, re.M))
    text = re.sub(r"load_steps=\d+", "load_steps=%d" % (ext + sub + 1), text, count=1)

    with open(full, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(text)
    print("patched", path)


def main():
    for path, (tex, sc, sh, bob) in SCENES.items():
        patch(path, tex, sc, sh, bob)


if __name__ == "__main__":
    main()