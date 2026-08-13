#!/usr/bin/env python3
"""
apply-keybindings.py

Apply key bindings or merge tool options to a Ghidra tool configuration.

The tool name determines which tcd file to modify:
  code_browser  -> _code.browser.tcd
  debugger      -> _debugger.tcd
  emulator      -> _emulator.tcd
  version_tracking -> _version_tracking.tcd

Usage:
  # Replace entire Key Bindings category (keybindings)
  apply-keybindings.py replace <tool_name> <kbxml_path> <tools_dir> <ghidra_install>

  # Merge tool options by CATEGORY NAME + element NAME (toolOptions)
  apply-keybindings.py merge <tool_name> <xml_file> <tools_dir> <ghidra_install>
"""

import os
import sys
import zipfile
import xml.etree.ElementTree as ET


TOOL_TCD_MAP = {
    "code_browser": "_code_browser",
    "debugger": "_debugger",
    "emulator": "_emulator",
    "version_tracking": "_version tracking",
}

# Mapping from tool name to .tool file location in Ghidra installation
TOOL_TOOL_MAP = {
    "code_browser": {
        "jar": "lib/ghidra/Ghidra/Configurations/Public_Release/lib/Public_Release.jar",
        "tool": "defaultTools/CodeBrowser.tool",
    },
    "debugger": {
        "jar": "lib/ghidra/Ghidra/Debug/Debugger/lib/Debugger.jar",
        "tool": "defaultTools/Debugger.tool",
    },
    "emulator": {
        "jar": "lib/ghidra/Ghidra/Debug/Debugger/lib/Debugger.jar",
        "tool": "defaultTools/Emulator.tool",
    },
    "version_tracking": {
        "jar": "lib/ghidra/Ghidra/Features/VersionTracking/lib/VersionTracking.jar",
        "tool": "defaultTools/VersionTracking.tool",
    },
}


def parse_kbxml_category(kbxml_path: str) -> ET.Element | None:
    """Parse the Key Bindings CATEGORY element from a .kbxml file."""
    tree = ET.parse(kbxml_path)
    root = tree.getroot()
    if root.tag == "CATEGORY" and root.get("NAME") == "Key Bindings":
        return ET.fromstring(ET.tostring(root))  # deepcopy
    return None


def copy_default_tcd_if_missing(tools_dir: str, tool_name: str, ghidra_install: str) -> None:
    """Fill missing TCDs with default .tool files when target tool's TCD is missing."""
    tcd_path = os.path.join(tools_dir, TOOL_TCD_MAP[tool_name] + ".tcd")
    if os.path.isfile(tcd_path):
        return

    # Fill each missing TCD with its default .tool file
    for name, prefix in TOOL_TCD_MAP.items():
        tcd_path = os.path.join(tools_dir, prefix + ".tcd")
        if os.path.isfile(tcd_path):
            continue

        tool_info = TOOL_TOOL_MAP[name]
        jar_path = os.path.join(ghidra_install, tool_info["jar"])
        tool_name_in_jar = tool_info["tool"]

        if not os.path.isfile(jar_path):
            print(f"ERROR: JAR not found: {jar_path}", file=sys.stderr)
            sys.exit(1)

        try:
            with zipfile.ZipFile(jar_path, "r") as zf:
                content = zf.read(tool_name_in_jar)
        except Exception as e:
            print(f"ERROR: Failed to extract {tool_name_in_jar} from {jar_path}: {e}", file=sys.stderr)
            sys.exit(1)

        os.makedirs(os.path.dirname(tcd_path), exist_ok=True)

        with open(tcd_path, "wb") as f:
            f.write(content)
        print(f"COPY {tool_name_in_jar} from {jar_path} -> {tcd_path}")


def apply_to_tcd(tcd_path: str, category: ET.Element) -> None:
    """Replace the Key Bindings category in the tcd file."""
    tree = ET.parse(tcd_path)
    root = tree.getroot()

    # Find OPTIONS element under first TOOL
    options_el = None
    for tool in root.iter("TOOL"):
        options_el = tool.find("OPTIONS")
        if options_el is not None:
            break

    if options_el is None:
        first_tool = next(iter(root.iter("TOOL")), None)
        if first_tool is None:
            print(f"ERROR: No <TOOL>/<OPTIONS> found in {tcd_path}", file=sys.stderr)
            sys.exit(1)
        options_el = ET.SubElement(first_tool, "OPTIONS")

    # Find existing Key Bindings category and replace it
    for cat in options_el.iter("CATEGORY"):
        if cat.get("NAME") == "Key Bindings":
            options_el.remove(cat)
            break

    # Add the new category (deepcopy)
    options_el.append(ET.fromstring(ET.tostring(category)))

    ET.indent(tree, space="    ")
    new_content = ET.tostring(tree.getroot(), encoding="utf-8", xml_declaration=True)

    # Only write if content has changed
    if os.path.isfile(tcd_path):
        with open(tcd_path, "rb") as f:
            old_content = f.read()
        if new_content == old_content:
            count = len(list(category.iter("WRAPPED_OPTION")))
            print(f"UNCHANGED {tcd_path}: {count} key bindings")
            return

    with open(tcd_path, "wb") as f:
        f.write(new_content)
    count = len(list(category.iter("WRAPPED_OPTION")))
    print(f"OK {tcd_path}: replaced with {count} key bindings")


def merge_categories_into_options(options_el: ET.Element, xml_categories: list[ET.Element]) -> int:
    """Merge XML categories into the OPTIONS element.

    For each CATEGORY in xml_categories:
      - Find matching CATEGORY by NAME in options_el
      - Within that category, match elements by NAME attribute
      - Replace matched elements, add new ones, preserve unmatched ones
      - Create CATEGORY if it doesn't exist

    Returns: number of elements merged
    """
    total_count = 0

    for xml_cat in xml_categories:
        cat_name = xml_cat.get("NAME", "")
        # Find existing category or create new one
        existing_cat = None
        for cat in options_el.iter("CATEGORY"):
            if cat.get("NAME") == cat_name:
                existing_cat = cat
                break

        if existing_cat is None:
            existing_cat = ET.SubElement(options_el, "CATEGORY")
            existing_cat.set("NAME", cat_name)

        # Build a map of existing elements by NAME
        existing_by_name: dict[str, ET.Element] = {}
        for child in list(existing_cat):
            name = child.get("NAME")
            if name is not None:
                existing_by_name[name] = child

        # Process elements from XML category
        for xml_elem in list(xml_cat):
            elem_name = xml_elem.get("NAME")
            if elem_name is None:
                continue

            if elem_name in existing_by_name:
                # Replace existing element
                existing_cat.remove(existing_by_name[elem_name])
                del existing_by_name[elem_name]

            # Add/insert the new element (deepcopy)
            new_elem = ET.fromstring(ET.tostring(xml_elem))
            existing_cat.append(new_elem)
            total_count += 1

    return total_count


def apply_merge(tcd_path: str, xml_file: str) -> None:
    """Merge XML categories into the tcd file's OPTIONS."""
    # Parse all CATEGORY elements from the XML file
    tree = ET.parse(xml_file)
    root = tree.getroot()

    # Collect all CATEGORY elements (could be root or nested)
    xml_categories: list[ET.Element] = []
    if root.tag == "CATEGORY":
        xml_categories.append(root)
    else:
        xml_categories = list(root.iter("CATEGORY"))

    if not xml_categories:
        print(f"WARN: No CATEGORY elements found in {xml_file}", file=sys.stderr)
        return

    # Parse the tcd file
    tcd_tree = ET.parse(tcd_path)
    tcd_root = tcd_tree.getroot()

    # Find OPTIONS element under first TOOL
    options_el = None
    for tool in tcd_root.iter("TOOL"):
        options_el = tool.find("OPTIONS")
        if options_el is not None:
            break

    if options_el is None:
        first_tool = next(iter(tcd_root.iter("TOOL")), None)
        if first_tool is None:
            print(f"ERROR: No <TOOL>/<OPTIONS> found in {tcd_path}", file=sys.stderr)
            sys.exit(1)
        options_el = ET.SubElement(first_tool, "OPTIONS")

    # Merge categories
    count = merge_categories_into_options(options_el, xml_categories)

    ET.indent(tcd_tree, space="    ")
    new_content = ET.tostring(tcd_tree.getroot(), encoding="utf-8", xml_declaration=True)

    # Only write if content has changed
    if os.path.isfile(tcd_path):
        with open(tcd_path, "rb") as f:
            old_content = f.read()
        if new_content == old_content:
            print(f"UNCHANGED {tcd_path}: {count} options")
            return

    with open(tcd_path, "wb") as f:
        f.write(new_content)
    print(f"OK {tcd_path}: merged {count} options")


def main() -> int:
    if len(sys.argv) < 6:
        print(f"Usage:\n  {sys.argv[0]} replace <tool_name> <kbxml_path> <tools_dir> <ghidra_install>\n"
              f"  {sys.argv[0]} merge <tool_name> <xml_file> <tools_dir> <ghidra_install>",
              file=sys.stderr)
        return 1

    subcommand = sys.argv[1]
    tool_name = sys.argv[2]

    if tool_name not in TOOL_TCD_MAP:
        print(f"ERROR: Unknown tool name '{tool_name}'. Valid: {', '.join(TOOL_TCD_MAP.keys())}",
              file=sys.stderr)
        return 1

    tcd_filename = TOOL_TCD_MAP[tool_name] + ".tcd"
    tools_dir = sys.argv[4]
    tcd_path = os.path.join(tools_dir, tcd_filename)

    # Copy default OPTIONS from .tool file if user tcd doesn't exist
    copy_default_tcd_if_missing(tools_dir, tool_name, sys.argv[5])

    if subcommand == "replace":
        if len(sys.argv) != 6:
            print(f"Usage: {sys.argv[0]} replace <tool_name> <kbxml_path> <tools_dir> <ghidra_install>",
                  file=sys.stderr)
            return 1

        category = parse_kbxml_category(sys.argv[3])
        if category is None:
            print(f"WARN: No Key Bindings category found in {sys.argv[3]}", file=sys.stderr)
            return 0

        apply_to_tcd(tcd_path, category)

    elif subcommand == "merge":
        if len(sys.argv) != 6:
            print(f"Usage: {sys.argv[0]} merge <tool_name> <xml_file> <tools_dir> <ghidra_install>",
                  file=sys.stderr)
            return 1

        apply_merge(tcd_path, sys.argv[3])

    else:
        print(f"ERROR: Unknown subcommand '{subcommand}'. Valid: replace, merge",
              file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
