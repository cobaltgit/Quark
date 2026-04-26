import std/[options, strutils, tables]

const SystemJson = "/mnt/UDISK/system.json"

type
  SystemConfig* = object
    values: Table[string, string]

## MainUI has a tendency to break JSON parsers by appending garbage to the end of the system.json.
## To get around this, we parse it manually - this is a very rudimentary parser with no support for arrays, which aren't present in system.json anyway.
proc parseJson(input: string): SystemConfig =
  result.values = initTable[string, string]()

  for line in input.splitLines():
    let colonPos = line.find(':')
    if colonPos > 0:
      let keyPart = line[0..<colonPos]
        .strip()
        .strip(chars = {'"', '\t', ' '})

      let valuePart = line[colonPos+1..^1]
        .strip()
        .strip(trailing = true, chars = {',', '}', '"'})
        .strip(leading = true, chars = {'"'})
        .strip()

      if keyPart.len > 0 and valuePart.len > 0:
        var isAlphaNum = true
        for c in keyPart:
          if not c.isAlphaNumeric:
            isAlphaNum = false
            break

        if isAlphaNum:
          result.values[keyPart] = valuePart

proc getString*(config: SystemConfig, key: string): Option[string] =
  if key in config.values:
    some(config.values[key])
  else:
    none(string)

proc getInt*(config: SystemConfig, key: string): Option[int] =
  if key in config.values:
    try:
      some(parseInt(config.values[key]))
    except ValueError:
      none(int)
  else:
    none(int)

proc getConfig*(): SystemConfig =
  parseJson(readFile(SystemJson))
