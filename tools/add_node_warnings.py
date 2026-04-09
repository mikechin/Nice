"""
Adds _warn_missing_nodes() to scene scripts that use the $Node if has_node() else null pattern.
Inserts a call at the end of _ready() and a helper method that push_warning for each null @onready var.

Usage: python tools/add_node_warnings.py
"""
import re
import glob
import os

SCENE_DIR = os.path.join(os.path.dirname(__file__), "..", "godot-project", "scenes")


def find_onready_vars(content: str) -> list[tuple[str, str]]:
    """Find all @onready vars with the has_node pattern. Returns [(var_name, node_path), ...]."""
    pattern = r'@onready var (\w+).*\$(.+?) if has_node\('
    return re.findall(pattern, content)


def has_warn_method(content: str) -> bool:
    return "_warn_missing_nodes" in content


def add_warnings(filepath: str) -> bool:
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    vars_found = find_onready_vars(content)
    if not vars_found or has_warn_method(content):
        return False

    # Build the warning method
    checks = []
    for var_name, node_path in vars_found:
        checks.append(f'\tif {var_name} == null:\n\t\tpush_warning("{os.path.basename(filepath)}: missing node {var_name}")')

    warn_method = "\n\nfunc _warn_missing_nodes() -> void:\n" + "\n".join(checks) + "\n"

    # Find _ready() and insert _warn_missing_nodes() call
    # Look for the end of _ready() — find next func or end of file
    ready_match = re.search(r'func _ready\(\).*?:\n', content)
    if not ready_match:
        return False

    # Check if _warn_missing_nodes() call already exists
    if "_warn_missing_nodes()" in content:
        return False

    # Insert call at the start of _ready() body (after the func line)
    insert_pos = ready_match.end()
    content = content[:insert_pos] + "\t_warn_missing_nodes()\n" + content[insert_pos:]

    # Append the method at the end of the file
    content = content.rstrip() + "\n" + warn_method

    with open(filepath, "w", encoding="utf-8") as f:
        f.write(content)

    return True


def main():
    files = glob.glob(os.path.join(SCENE_DIR, "**", "*.gd"), recursive=True)
    modified = 0
    for f in sorted(files):
        if add_warnings(f):
            print(f"  Updated: {os.path.relpath(f, os.path.join(SCENE_DIR, '..', '..'))}")
            modified += 1
    print(f"\nModified {modified} files")


if __name__ == "__main__":
    main()
