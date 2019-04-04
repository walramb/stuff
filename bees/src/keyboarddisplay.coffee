keyboardrows=["1234567890"
"QWERTYUIOP"
"ASDFGHJKL"
"ZXCVBNM"]


#input is an object of keys and title text for keys to highlight
EXAMPLEINPUT= { "W": "up", "S": "down" }

visualizekeyboard = (mappings) ->
  
  output = "<div class='keyboardlayout'>"
  for row in keyboardrows
    output += "<div>"
    for key in row
      if mappings[key]?
        text=mappings[key]
        output += "<span class='highlight' title='#{text}'>#{key}</span>"
      else
        output += "<span>#{key}</span>"
    output += "</div>"
  return output


root = exports ? this

root.keyboardlayout = {}
root.keyboardlayout.visualize = visualizekeyboard


