#!/usr/bin/env python3
"""xcodegen이 resources를 누락하므로 pbxproj에 리소스 등록을 멱등 패치.

사용법: xcodegen generate 직후 실행.
    python3 scripts/patch-resources.py
이미 패치되어 있으면 OK만 출력하고 종료.
"""
import sys

PBX = "WebIsland.xcodeproj/project.pbxproj"

U = {
    "BF_LOC": "B02DCFADDCD94393AB002875",
    "BF_INFO": "4E9D5606E58344EA88ED35AF",
    "BF_XC": "9D818B380A6645BFB9C63F0F",
    "FR_EN_LOC": "A3C1F83D1A7548A48D9DD696",
    "FR_KO_LOC": "8A3FF384FEA54EBD8B12AAD0",
    "FR_EN_INFO": "BA5705DCB7E44AFC9700380E",
    "FR_KO_INFO": "9DD29EC84BC441ECAD7A3B34",
    "VG_LOC": "EDBA35E4747F4125BBB367E1",
    "VG_INFO": "9E11315151004BE0B81D684C",
    "FR_XC": "B1419D6AAF034B2686124369",
    "PH_RES": "5729DC9C606A4E2FB7577D17",
    "GR_ASSETS": "8434A4A5C7AE4F3AB598C3BD",
}

T = "\t\t"


def one(content, anchor, insert, label):
    count = content.count(anchor)
    if count != 1:
        sys.exit(f"FAIL: anchor '{label}' found {count}x (expected 1)")
    return content.replace(anchor, insert + anchor, 1)


def swap(content, old, new, label):
    """앵커 블록 전체 교체 (중복 삽입 방지)."""
    count = content.count(old)
    if count != 1:
        sys.exit(f"FAIL: swap anchor '{label}' found {count}x (expected 1)")
    return content.replace(old, new, 1)


def main():
    with open(PBX) as f:
        content = f.read()
    if "PBXResourcesBuildPhase" in content:
        print("OK: resources already registered")
        return

    content = one(
        content,
        "/* End PBXBuildFile section */",
        f"{T}{U['BF_LOC']} /* Localizable.strings in Resources */ = {{isa = PBXBuildFile; fileRef = {U['VG_LOC']} /* Localizable.strings */; }};\n"
        f"{T}{U['BF_INFO']} /* InfoPlist.strings in Resources */ = {{isa = PBXBuildFile; fileRef = {U['VG_INFO']} /* InfoPlist.strings */; }};\n"
        f"{T}{U['BF_XC']} /* WebIsland.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {U['FR_XC']} /* WebIsland.xcassets */; }};\n",
        "buildfile-end",
    )
    content = one(
        content,
        "/* End PBXFileReference section */",
        f"{T}{U['FR_EN_LOC']} /* en */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.strings; name = en; path = Resources/en.lproj/Localizable.strings; sourceTree = \"<group>\"; }};\n"
        f"{T}{U['FR_KO_LOC']} /* ko */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.strings; name = ko; path = Resources/ko.lproj/Localizable.strings; sourceTree = \"<group>\"; }};\n"
        f"{T}{U['FR_EN_INFO']} /* en */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.strings; name = en; path = Resources/en.lproj/InfoPlist.strings; sourceTree = \"<group>\"; }};\n"
        f"{T}{U['FR_KO_INFO']} /* ko */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.strings; name = ko; path = Resources/ko.lproj/InfoPlist.strings; sourceTree = \"<group>\"; }};\n"
        f"{T}{U['FR_XC']} /* WebIsland.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = WebIsland.xcassets; sourceTree = \"<group>\"; }};\n",
        "fileref-end",
    )
    content = one(
        content,
        "\t\t\t\tE0F2208E0A957EDA3A6C3F59 /* Products */,\n",
        f"\t\t\t\t{U['GR_ASSETS']} /* Assets */,\n"
        f"\t\t\t\t{U['VG_LOC']} /* Localizable.strings */,\n"
        f"\t\t\t\t{U['VG_INFO']} /* InfoPlist.strings */,\n",
        "maingroup-children",
    )
    content = one(
        content,
        "/* End PBXGroup section */",
        f"{T}{U['GR_ASSETS']} /* Assets */ = {{\n"
        f"{T}\tisa = PBXGroup;\n"
        f"{T}\tchildren = (\n"
        f"{T}\t\t{U['FR_XC']} /* WebIsland.xcassets */,\n"
        f"{T}\t);\n"
        f"{T}\tpath = Assets;\n"
        f"{T}\tsourceTree = \"<group>\";\n"
        f"{T}}};\n",
        "assets-group",
    )
    content = swap(
        content,
        f"C76D1C82F23899B4187BFDD5 /* Frameworks */,\n\t\t\t);",
        f"C76D1C82F23899B4187BFDD5 /* Frameworks */,\n\t\t\t\t{U['PH_RES']} /* Resources */,\n\t\t\t);",
        "target-phases",
    )
    content = one(
        content,
        "/* Begin PBXSourcesBuildPhase section */",
        f"/* Begin PBXResourcesBuildPhase section */\n"
        f"{T}{U['PH_RES']} /* Resources */ = {{\n"
        f"{T}\tisa = PBXResourcesBuildPhase;\n"
        f"{T}\tbuildActionMask = 2147483647;\n"
        f"{T}\tfiles = (\n"
        f"{T}\t\t{U['BF_LOC']} /* Localizable.strings in Resources */,\n"
        f"{T}\t\t{U['BF_INFO']} /* InfoPlist.strings in Resources */,\n"
        f"{T}\t\t{U['BF_XC']} /* WebIsland.xcassets in Resources */,\n"
        f"{T}\t);\n"
        f"{T}\trunOnlyForDeploymentPostprocessing = 0;\n"
        f"{T}}};\n"
        "/* End PBXResourcesBuildPhase section */\n\n",
        "resources-phase",
    )
    content = one(
        content,
        "/* End PBXTargetDependency section */",
        "/* End PBXTargetDependency section */\n\n"
        "/* Begin PBXVariantGroup section */\n"
        f"{T}{U['VG_LOC']} /* Localizable.strings */ = {{\n"
        f"{T}\tisa = PBXVariantGroup;\n"
        f"{T}\tchildren = (\n"
        f"{T}\t\t{U['FR_EN_LOC']} /* en */,\n"
        f"{T}\t\t{U['FR_KO_LOC']} /* ko */,\n"
        f"{T}\t);\n"
        f"{T}\tname = Localizable.strings;\n"
        f"{T}\tsourceTree = \"<group>\";\n"
        f"{T}}};\n"
        f"{T}{U['VG_INFO']} /* InfoPlist.strings */ = {{\n"
        f"{T}\tisa = PBXVariantGroup;\n"
        f"{T}\tchildren = (\n"
        f"{T}\t\t{U['FR_EN_INFO']} /* en */,\n"
        f"{T}\t\t{U['FR_KO_INFO']} /* ko */,\n"
        f"{T}\t);\n"
        f"{T}\tname = InfoPlist.strings;\n"
        f"{T}\tsourceTree = \"<group>\";\n"
        f"{T}}};\n"
        "/* End PBXVariantGroup section */",
        "variant-groups",
    )
    content = swap(
        content,
        "\t\t\tknownRegions = (\n\t\t\t\tBase,\n\t\t\t\ten,\n\t\t\t);",
        "\t\t\tknownRegions = (\n\t\t\t\tBase,\n\t\t\t\ten,\n\t\t\t\tko,\n\t\t\t);",
        "known-regions",
    )
    with open(PBX, "w") as f:
        f.write(content)
    print("PATCHED: resources registered")


main()
