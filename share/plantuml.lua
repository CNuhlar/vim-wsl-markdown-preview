-- pandoc filter: render ```plantuml / ```puml / ```uml code blocks to inline SVG.
-- Diagrams are cached by content hash, so unchanged diagrams don't start java again.
local share = os.getenv('HOME') .. '/.local/share/mdview'
local cache = os.getenv('HOME') .. '/.cache/mdview/plantuml'
os.execute('mkdir -p ' .. cache)

local function render(src)
  if not src:match('@start') then
    src = '@startuml\n' .. src .. '\n@enduml\n'
  end
  local path = cache .. '/' .. pandoc.sha1(src) .. '.svg'
  local f = io.open(path, 'r')
  if f then
    local svg = f:read('a')
    f:close()
    return svg
  end
  local ok, svg = pcall(pandoc.pipe, 'java',
    { '-Djava.awt.headless=true', '-jar', share .. '/plantuml.jar',
      '-tsvg', '-Playout=smetana', '-charset', 'UTF-8', '-pipe' }, src)
  if not ok then
    return nil
  end
  f = io.open(path, 'w')
  if f then
    f:write(svg)
    f:close()
  end
  return svg
end

function CodeBlock(el)
  local cls = el.classes[1]
  if cls ~= 'plantuml' and cls ~= 'puml' and cls ~= 'uml' then
    return nil
  end
  local svg = render(el.text)
  if not svg then
    return nil
  end
  -- drop the xml prolog; keep the data-pos attributes so scroll sync still works
  svg = svg:gsub('^<%?xml[^>]*%?>', '')
  local attrs = ''
  for k, v in pairs(el.attributes) do
    attrs = attrs .. ' ' .. k .. '="' .. v .. '"'
  end
  return pandoc.RawBlock('html', '<div class="plantuml"' .. attrs .. '>' .. svg .. '</div>')
end
