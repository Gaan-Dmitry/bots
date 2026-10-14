import win32con

# Ультра-темная палитра Cyber-Glass (Catppuccin Mocha + Neon)
THEME = {
    "transparent_key": "#000001",
    "bg": "#11111B",
    "card": "#181825",
    "card_border": "#27273A",
    "border_idle": "#313244",
    "border_active": "#A6E3A1",
    "text": "#CDD6F4",
    "subtext": "#6C7086",
    "druid": "#A6E3A1",
    "warlock": "#CBA6F7",
    "btn_start": "#238636",
    "btn_start_hover": "#2EA043",
    "btn_pause": "#DA3633",
    "btn_pause_hover": "#F85149",
    "aoe_on": "#FE640B",
    "aoe_off": "#212130",
    "btn_neutral": "#212130",
    "btn_neutral_hover": "#313244",
}

BOT_TICK_INTERVAL = 0.16
COLOR_TOLERANCE = 4

VK_MAP = {
    "{F5}": win32con.VK_F5,
    "{F6}": win32con.VK_F6,
    "{F7}": win32con.VK_F7,
    "{F8}": win32con.VK_F8,
    "{F9}": win32con.VK_F9,
    "{F10}": win32con.VK_F10,
    "{F11}": win32con.VK_F11,
    "{F12}": win32con.VK_F12,
    "{Numpad0}": win32con.VK_NUMPAD0,
    "{Numpad1}": win32con.VK_NUMPAD1,
    "{Numpad2}": win32con.VK_NUMPAD2,
    "{Numpad3}": win32con.VK_NUMPAD3,
    "{Numpad4}": win32con.VK_NUMPAD4,
    "{Numpad5}": win32con.VK_NUMPAD5,
    "{Numpad6}": win32con.VK_NUMPAD6,
    "{Numpad7}": win32con.VK_NUMPAD7,
    "{Numpad8}": win32con.VK_NUMPAD8,
    "{Numpad9}": win32con.VK_NUMPAD9,
    "{Space}": win32con.VK_SPACE,
    "{BS}": win32con.VK_BACK,
    "-": 0xBD,
    "=": 0xBB,
    "s": 0x53,  # Клавиша S (шаг назад для сброса /follow и фиксации на месте)
}