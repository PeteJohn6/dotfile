local wezterm = require("wezterm")

local function is_found(value, pattern)
  return string.find(value, pattern) ~= nil
end

local function platform()
  local is_win = is_found(wezterm.target_triple, "windows")
  local is_linux = is_found(wezterm.target_triple, "linux")
  local is_mac = is_found(wezterm.target_triple, "apple")

  if is_win then
    return {
      os = "windows",
      is_win = true,
      is_linux = false,
      is_mac = false,
    }
  end

  if is_linux then
    return {
      os = "linux",
      is_win = false,
      is_linux = true,
      is_mac = false,
    }
  end

  if is_mac then
    return {
      os = "mac",
      is_win = false,
      is_linux = false,
      is_mac = true,
    }
  end

  error("Unknown platform")
end

return platform()
