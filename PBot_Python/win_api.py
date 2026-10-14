import ctypes
import time
import win32api
import win32con
import win32gui
from config import VK_MAP

user32 = ctypes.windll.user32
gdi32 = ctypes.windll.gdi32


def is_window_valid(hwnd: int) -> bool:
  return bool(hwnd and win32gui.IsWindow(hwnd))


def make_window_noactivate(tk_root):
  """
    Делает окно бота неактивируемым при клике (WS_EX_NOACTIVATE),
    чтобы оно никогда не забирало фокус у окна World of Warcraft.
    """
  tk_root.update_idletasks()
  hwnd = user32.GetParent(tk_root.winfo_id())
  if not hwnd:
    hwnd = tk_root.winfo_id()

  ex_style = win32gui.GetWindowLong(hwnd, win32con.GWL_EXSTYLE)
  # WS_EX_NOACTIVATE = 0x08000000, WS_EX_TOPMOST = 0x00000008
  new_style = ex_style | 0x08000000 | win32con.WS_EX_TOPMOST
  win32gui.SetWindowLong(hwnd, win32con.GWL_EXSTYLE, new_style)


def get_mouse_client_pos():
  cursor_pos = win32gui.GetCursorPos()
  hwnd = win32gui.WindowFromPoint(cursor_pos)
  if not hwnd:
    return 0, 0, 0

  root_hwnd = win32gui.GetAncestor(hwnd, win32con.GA_ROOT)
  if root_hwnd:
    hwnd = root_hwnd

  client_x, client_y = win32gui.ScreenToClient(hwnd, cursor_pos)
  return hwnd, client_x, client_y


def get_background_pixel_color(hwnd: int, x: int, y: int):
  if not is_window_valid(hwnd):
    return None

  hdc = user32.GetDC(hwnd)
  if not hdc:
    return None

  try:
    color_bgr = gdi32.GetPixel(hdc, x, y)
    if color_bgr == 0xFFFFFFFF or color_bgr < 0:
      return None

    r = color_bgr & 0xFF
    g = (color_bgr >> 8) & 0xFF
    b = (color_bgr >> 16) & 0xFF
    return (r, g, b)
  finally:
    user32.ReleaseDC(hwnd, hdc)


def control_send(hwnd: int, key_str: str):
  if not is_window_valid(hwnd):
    return

  vk = VK_MAP.get(key_str)
  if not vk:
    return

  scan_code = user32.MapVirtualKeyW(vk, 0)
  lparam_down = (scan_code << 16) | 1
  lparam_up = (scan_code << 16) | 0xC0000001

  win32api.PostMessage(hwnd, win32con.WM_KEYDOWN, vk, lparam_down)
  win32api.PostMessage(hwnd, win32con.WM_KEYUP, vk, lparam_up)


def control_send_hold(hwnd: int, key_str: str, hold_sec: float = 0.06):
  """Зажимает клавишу на hold_sec секунд (нужно для гарантированной остановки бега)"""
  if not is_window_valid(hwnd):
    return

  vk = VK_MAP.get(key_str)
  if not vk:
    return

  scan_code = user32.MapVirtualKeyW(vk, 0)
  lparam_down = (scan_code << 16) | 1
  lparam_up = (scan_code << 16) | 0xC0000001

  win32api.PostMessage(hwnd, win32con.WM_KEYDOWN, vk, lparam_down)
  time.sleep(hold_sec)
  win32api.PostMessage(hwnd, win32con.WM_KEYUP, vk, lparam_up)