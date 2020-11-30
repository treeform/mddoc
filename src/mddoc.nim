import json, os, re, strutils

var docs = newJArray()
var doneFiles: seq[string]

proc scanNimFile(path: string) =
  if path in doneFiles:
    return
  echo "using ", path
  discard os.execShellCmd("nim jsondoc -o:doc.json " & path)
  var doc = parseJson(readFile("doc.json"))
  docs.add(doc)
  removeFile("doc.json")
  doneFiles.add(path)
  for line in readFile(path).split("\n"):
    if line.startsWith("export"):
      for module in line["export ".len .. ^1].split(","):
        var module = module.strip()
        for f in walkDirRec("."):
          if f.extractFilename == module & ".nim":
            scanNimFile(f)

proc genMarkDownFile() =
  var md = ""
  var i = 0
  for doc in docs:
    if i == 0:
      md.add "# API: " & doc["nimble"].getStr() & "\n"
      md.add "\n```nim\n"
      md.add "import " & doc["nimble"].getStr() & "\n"
      md.add "```\n"
      md.add "\n"
      if "description" in doc and doc["moduleDescription"].getStr() != "":
        md.add doc["moduleDescription"].getStr()
        md.add "\n"

    for entry in doc["entries"]:
      #echo "* ", entry["name"].getStr()
      md.add "## **" & entry["type"].getStr()[2..^1].toLowerAscii() & "** "
      md.add entry["name"].getStr()
        .replace("&lt;", "<")
        .replace("&gt;", ">")
      md.add "\n\n"
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
        #echo entry["code"].getStr()
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
      inc i
    md = "\n" & md.strip() & "\n"

  var readme = readFile("README.md")
  let loc = readme.find("\n# API: ")
  if loc == -1:
    readme.add md
  else:
    readme = readme[0 ..< loc] & md
  writeFile("README.md", readme)

if dirExists("src"):
  for kind, file in walkDir("src"):
    if kind == pcFile and file.endsWith(".nim"):
      scanNimFile(file)

  genMarkDownFile()
