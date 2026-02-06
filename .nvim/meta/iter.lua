---@meta vim.iter

-- emmylua_ls doesn't pickup on @operator call:Iter
-- it uses @overload fun() instead, which vim.iter does not

---@param t table|function
---@return Iter
vim.iter = function(t) end
