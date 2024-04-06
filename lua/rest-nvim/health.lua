---@mod rest-nvim.health rest.nvim healthcheck
---
---@brief [[
---
---Healthcheck module for rest.nvim
---
---@brief ]]

local health = {}

local function install_health()
  vim.health.start("Installation")

  -- Luarocks dependencies existence checking
  for dep, dep_info in pairs(vim.g.rest_nvim_deps) do
    if not dep_info.found then
      local err_advice = "Install it through `sudo luarocks install " .. dep .. "`"
      if dep:find("nvim") then
        err_advice = "Install it through your preferred plugins manager or luarocks by using `luarocks --local install "
          .. dep
          .. "`"
        -- NOTE: nvim-treesitter has a weird bug in luarocks due to the parsers installation logic so let's mark it as not recommended
        if dep == "nvim-treesitter" then
          err_advice = err_advice .. " (not recommended yet!)"
        end
      end

      vim.health.error("Dependency `" .. dep .. "` was not found (" .. dep_info.error .. ")", err_advice)
    else
      vim.health.ok("Dependency `" .. dep .. "` was found")
    end
  end

  -- Tree-sitter and HTTP parser
  local found_treesitter, ts_info = pcall(require, "nvim-treesitter.info")
  if not found_treesitter then
    vim.health.warn(
      "Could not check for tree-sitter `http` parser existence because `nvim-treesitter` is not installed"
    )
  else
    local is_http_parser_installed = vim.tbl_contains(ts_info.installed_parsers(), "http")
    if not is_http_parser_installed then
      vim.health.error(
        "Tree-sitter `http` parser is not installed (rest.nvim parsing will not work.)",
        "Install it through `:TSInstall http` or add it to your `nvim-treesitter`'s `ensure_installed` table."
      )
    else
      vim.health.ok("Tree-sitter `http` parser is installed")
    end
  end
end

local function configuration_health()
  vim.health.start("Configuration")

  -- Configuration options
  local unrecognized_configs = _G._rest_nvim.debug_info.unrecognized_configs
  if not vim.tbl_isempty(unrecognized_configs) then
    for _, config_key in ipairs(unrecognized_configs) do
      vim.health.warn("Unrecognized configuration option `" .. config_key .. "` found")
    end
  else
    vim.health.ok("No unrecognized configuration options were found")
  end

  -- Formatters
  local formatters = _G._rest_nvim.result.behavior.formatters
  for ft, formatter in pairs(formatters) do
    if type(formatter) == "string" then
      if vim.fn.executable(formatter) ~= 1 then
        vim.health.warn(
          "Formatter for `"
            .. ft
            .. "` is set to `"
            .. formatter
            .. "`, however, rest.nvim could not find it in your system"
        )
      else
        vim.health.ok(
          "Formatter for `" .. ft .. "` is set to `" .. formatter .. "` and rest.nvim found it in your system"
        )
      end
    elseif type(formatter) == "function" then
      local _, fmt_meta = formatter()
      if not fmt_meta.found then
        vim.health.warn(
          "Formatter for `"
            .. ft
            .. "` is set to `"
            .. fmt_meta.name
            .. "`, however, rest.nvim could not find it in your system"
        )
      else
        vim.health.ok(
          "Formatter for `" .. ft .. "` is set to `" .. fmt_meta.name .. "` and rest.nvim found it in your system"
        )
      end
    end
  end
end

function health.check()
  install_health()
  configuration_health()
end

return health
