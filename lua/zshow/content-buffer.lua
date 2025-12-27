---@class zshow.ContentBuffer.line_token
---@field private _text string
---@field private _hl? string
local Token = {}

function Token.new(text, hl)
    return setmetatable({ _text = text, _hl = hl }, { __index = Token })
end
function Token:get_text() return self._text end
function Token:get_hl() return self._hl end

---@class zshow.ContentBuffer
---@field private lines table
---@field private pos integer
local ContentBuffer = {}

function ContentBuffer.new()
    return setmetatable(
        { lines = {}, pos = 0 },
        { __index = ContentBuffer }
    )
end

---@param text string
---@param hl? string
function ContentBuffer:append(text, hl)
    ---@diagnostic disable-next-line
    if self.pos == 0 then
        self.lines[#self.lines+1] = {}
        self.pos = 1
    elseif not self.lines[self.pos] then
        self.lines[self.pos] = {}
    end

    local line = self.lines[self.pos]
    line[#line+1] = Token.new(text, hl)

    return self
end

function ContentBuffer:endl()
    self.pos = self.pos + 1

    return self
end

function ContentBuffer:empty_line()
    self.lines[#self.lines+1] = { Token.new('') }
    self.pos = #self.lines + 1

    return self
end

function ContentBuffer:linecount() return #self.lines end

---@param lineno integer
function ContentBuffer:get_line_text(lineno)
    return vim.iter(self.lines[lineno])
        :map(function (tok) return tok:get_text() end)
        :join('')
end

function ContentBuffer:token_iter(lineno)
    return ipairs(self.lines[lineno])
end

return ContentBuffer
