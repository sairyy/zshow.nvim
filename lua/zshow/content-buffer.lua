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

function get_line_text(line)
    return vim.iter(line)
        :map(function (tok) return tok:get_text() end)
        :join('')
end

---@return string[]
function ContentBuffer:get_full_text()
    return vim.iter(self.lines)
        :map(function(line) return get_line_text(line) end)
        :totable()
end

function ContentBuffer:token_iter()
    local i = 0
    local line = 1
    local col_start, col_end = 1, 1

    ---@return integer, integer, integer, zshow.ContentBuffer.line_token
    return function ()
        i = i + 1

        -- move over to the next line
        if i > #self.lines[line] then
            ---@diagnostic disable-next-line: missing-return-value
            ---end of buffer
            if line + 1 > #self.lines then return end

            line, i = line + 1, 1
            col_start, col_end = 1, 1
        end

        ---@type zshow.ContentBuffer.line_token
        local token = self.lines[line][i]
        col_start = col_end
        col_end = col_end + token:get_text():len()

        return line, col_start, col_end, token
    end
end

return ContentBuffer
