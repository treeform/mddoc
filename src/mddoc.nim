import os, json, strutils, re

if paramCount() != 1:
  echo "Got to the root of your library, where the README.md is."
  echo "Usage: mddoc path/to/library.nim"
  quit()

echo paramStr(1)

discard os.execShellCmd("nim jsondoc -o:doc.json " & paramStr(1))

var doc = parseJson(readFile("doc.json"))

var md = ""
md.add "# API: " & doc["nimble"].getStr() & "\n"
md.add "\n```nim\n"
md.add "import " & doc["nimble"].getStr() & "\n"
md.add "```\n"
md.add "\n"
if "description" in doc and doc["moduleDescription"].getStr() != "":
  md.add doc["moduleDescription"].getStr()
  md.add "\n"

for entry in doc["entries"]:
  echo "* ", entry["name"].getStr()
  md.add "## **" & entry["type"].getStr()[2..^1].toLowerAscii() & "** " & entry["name"].getStr() & "\n"
  md.add "\n"
  if "description" in entry:
    md.add entry["description"].getStr()
      .replace("<ul class=\"simple\">", "\n")
      .replace("<li>", " * ")
      .replace("</li>", "")
      .replace("</ul>", "")
      .replace("&gt;", ">")
      .replace("&quot;", "\"")
      .strip()
    md.add "\n"
  if "code" in entry:
    md.add "\n```nim\n"
    echo entry["code"].getStr()
    md.add entry["code"].getStr()
      .replace(".\n", ".")
      .replace(",\n", ", ")
      .replace(", raises: []", "")
      .replace(", tags: []", "")
      .replace(re" +", " ")
      .replace("{. raises", "{.raises")
      .replace(".raises: [], ", "")
      .replace("{.raises: [], tags: [].}", "")
      .replace("{.raises: [].}", "")
      .replace("{tags: [].}", "")
      .strip()
    md.add "\n```\n"
  md.add "\n"
md = "\n" & md.strip() & "\n"

var readme = readFile("README.md")
let loc = readme.find("\n# API: ")
if loc == -1:
  readme.add md
else:
  readme = readme[0 ..< loc] & md
writeFile("README.md", readme)

removeFile("doc.json")
