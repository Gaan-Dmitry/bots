import logging
import random
import threading
import time
from config import BOT_TICK_INTERVAL, COLOR_TOLERANCE
from win_api import control_send, control_send_hold, get_background_pixel_color, is_window_valid

logger = logging.getLogger(__name__)


def near(val: int, target: int) -> bool:
  return abs(val - target) <= COLOR_TOLERANCE


class BotEngine:

  def __init__(self, ui_callback):
    self.ui_callback = ui_callback
    self.bot_running = False

    # --- Переменные Друида (Хил) ---
    self.druid_win_id = 0
    self.client_x = 14
    self.client_y = 14
    self.last_sent_key = ""
    self.last_sent_time = 0.0

    # --- Переменные Чернокнижника (Демон) ---
    self.lock_win_id = 0
    self.lock_x = 14
    self.lock_y = 14
    self.last_lock_key = ""
    self.last_lock_time = 0.0
    self.lock_aoe_mode = False
    self.lock_lifetap_remaining = 0

    self._thread = threading.Thread(target=self._loop, daemon=True)
    self._thread.start()

  def send_smart_key(self, key: str, info: str, cooldown_ms: int = 650):
    now = time.time() * 1000
    if key == self.last_sent_key and (now - self.last_sent_time) < cooldown_ms:
      return False
    control_send(self.druid_win_id, key)
    self.last_sent_key = key
    self.last_sent_time = now
    self.ui_callback("druid", info)
    return True

  def send_lock_key(self, key: str, info: str, cooldown_ms: int = 650):
    now = time.time() * 1000
    if key == self.last_lock_key and (now - self.last_lock_time) < cooldown_ms:
      return False
    control_send(self.lock_win_id, key)
    self.last_lock_key = key
    self.last_lock_time = now
    self.ui_callback("lock", info)
    return True

  def face_target_lock(self):
    """
        Поворачивает лока лицом к цели танка:
        1. Numpad3 (/target focustarget)
        2. Numpad5 (Interact with Target -> клиент поворачивает персонажа)
        3. Через 120 мс короткий шаг назад 's', чтобы остановить движение
        """
    now = time.time() * 1000
    if (
        self.last_lock_key == "FACE"
        and (now - self.last_lock_time) < 900
    ):
      return
    self.last_lock_key = "FACE"
    self.last_lock_time = now
    self.ui_callback("lock", "🔄 Разворот лицом к мобу!")

    def _do_turn():
      control_send(self.lock_win_id, "{Numpad3}")
      time.sleep(0.05)
      control_send(self.lock_win_id, "{Numpad5}")
      time.sleep(0.14)
      control_send_hold(self.lock_win_id, "s", 0.05)

    threading.Thread(target=_do_turn, daemon=True).start()

  def stop_movement(self, hwnd: int, channel: str):
    """Короткое нажатие S (50 мс) для сброса /follow и остановки на рендже"""
    now = time.time() * 1000
    if channel == "lock":
      if self.last_lock_key == "s" and (now - self.last_lock_time) < 700:
        return
      self.last_lock_key = "s"
      self.last_lock_time = now
    else:
      if self.last_sent_key == "s" and (now - self.last_sent_time) < 700:
        return
      self.last_sent_key = "s"
      self.last_sent_time = now

    self.ui_callback(channel, "🛑 Держу рендж (Стоп бег)")
    threading.Thread(
        target=control_send_hold, args=(hwnd, "s", 0.05), daemon=True
    ).start()

  def bind_druid(self, hwnd: int, x: int, y: int):
    self.druid_win_id = hwnd
    self.client_x = x
    self.client_y = y
    self.ui_callback("druid", f"Привязан [ID:{hwnd} | {x},{y}]")
    color = get_background_pixel_color(hwnd, x, y)
    if color:
      self.ui_callback("druid_color", color)

  def bind_lock(self, hwnd: int, x: int, y: int):
    self.lock_win_id = hwnd
    self.lock_x = x
    self.lock_y = y
    self.ui_callback("lock", f"Привязан [ID:{hwnd} | {x},{y}]")
    color = get_background_pixel_color(hwnd, x, y)
    if color:
      self.ui_callback("lock_color", color)

  def toggle_bot(self):
    if self.druid_win_id == 0 and self.lock_win_id == 0:
      self.ui_callback("druid", "⚠️ Сначала привяжи F3 или Shift+F3!")
      return

    self.bot_running = not self.bot_running
    self.ui_callback("state", self.bot_running)

  def toggle_aoe_mode(self):
    self.lock_aoe_mode = not self.lock_aoe_mode
    self.ui_callback("aoe_state", self.lock_aoe_mode)
    status_text = (
        "Режим: Семя порчи (АОЕ)"
        if self.lock_aoe_mode
        else "Режим: Соло в Босса"
    )
    self.ui_callback("lock", status_text)

  def focus_and_follow(self):
    if self.druid_win_id != 0:
      control_send(self.druid_win_id, "{F5}")
      self.ui_callback("druid", "🎯 Танк в Фокусе + /follow!")
    if self.lock_win_id != 0:
      control_send(self.lock_win_id, "{F5}")
      self.ui_callback("lock", "🎯 Танк в Фокусе + /follow!")

  def unstuck_jump(self):
    if self.druid_win_id != 0:
      control_send(self.druid_win_id, "{Space}")
      threading.Timer(
          0.35, lambda: control_send(self.druid_win_id, "{Numpad6}")
      ).start()
      self.ui_callback("druid", "🦘 Прыжок + /follow")
    if self.lock_win_id != 0:
      control_send(self.lock_win_id, "{Space}")
      threading.Timer(
          0.35, lambda: control_send(self.lock_win_id, "{Numpad6}")
      ).start()
      self.ui_callback("lock", "🦘 Прыжок + /follow")

  def _loop(self):
    while True:
      if self.bot_running:
        try:
          self.heal_tick()
          self.lock_tick()
        except Exception:
          # Не даём одной ошибке навсегда остановить цикл, оставляя HUD активным.
          logger.exception("Ошибка фонового цикла бота; повтор через 1 секунду")
          try:
            self.ui_callback("druid", "ОШИБКА цикла — см. logs/pbot-runtime.log")
          except Exception:
            logger.debug("Не удалось обновить HUD после ошибки цикла", exc_info=True)
          time.sleep(1.0)
      time.sleep(BOT_TICK_INTERVAL)

  def heal_tick(self):
    if self.druid_win_id == 0 or not is_window_valid(self.druid_win_id):
      return

    color = get_background_pixel_color(
        self.druid_win_id, self.client_x, self.client_y
    )
    if not color:
      return

    self.ui_callback("druid_color", color)
    _, G, B = color

    if G < 10 and B < 10:
      self.ui_callback("druid", "Группа здорова | Ожидание")
      return

    if B > 20:
      if near(B, 60):
        self.send_smart_key("{Numpad9}", "🧪 Диспел ➔ СЕБЯ")
      elif near(B, 100):
        self.send_smart_key("{Numpad0}", "✝️ Рес / Диспел ➔ Party 1")
      elif near(B, 140):
        self.send_smart_key("-", "✝️ Рес / Диспел ➔ Party 2")
      elif near(B, 180):
        self.send_smart_key("=", "✝️ Рес / Диспел ➔ Party 3")
      elif near(B, 220):
        self.send_smart_key("{BS}", "✝️ Рес / Диспел ➔ Party 4")
      return

    if near(G, 40):
      self.send_smart_key("{F6}", "💚 Омоложение ➔ СЕБЯ")
    elif near(G, 60):
      self.send_smart_key("{F7}", "💚 Омоложение ➔ Party 1")
    elif near(G, 80):
      self.send_smart_key("{F8}", "💚 Омоложение ➔ Party 2")
    elif near(G, 100):
      self.send_smart_key("{F9}", "💚 Омоложение ➔ Party 3")
    elif near(G, 120):
      self.send_smart_key("{F10}", "💚 Омоложение ➔ Party 4")
    elif near(G, 140):
      self.send_smart_key("{F11}", "⚡ Сейв/Восст ➔ СЕБЯ", 900)
    elif near(G, 160):
      self.send_smart_key("{F12}", "⚡ Сейв/Восст ➔ Party 1", 900)
    elif near(G, 180):
      self.send_smart_key("{Numpad1}", "⚡ Сейв/Восст ➔ Party 2", 900)
    elif near(G, 200):
      self.send_smart_key("{Numpad2}", "⚡ Сейв/Восст ➔ Party 3", 900)
    elif near(G, 210):
      self.stop_movement(self.druid_win_id, "druid")
    elif near(G, 220):
      self.send_smart_key("{Numpad3}", "⚡ Сейв/Восст ➔ Party 4", 900)
    elif near(G, 230):
      self.send_smart_key("{Numpad4}", "🌿 Буйный рост (АОЕ)")
    elif near(G, 240):
      self.send_smart_key("{Numpad5}", "💧 Озарение + Кожа")
    elif near(G, 245):
      self.send_smart_key("{Numpad8}", "🛑 СТОП-КАСТ (Оверхил)", 200)
    elif near(G, 250):
      self.send_smart_key("{Numpad6}", "🏃 Возврат на /follow focus", 800)
    elif near(G, 255):
      self.send_smart_key("{Numpad7}", "🐆 Походный облик + /follow", 1000)

  def lock_tick(self):
    if self.lock_win_id == 0 or not is_window_valid(self.lock_win_id):
      return

    color = get_background_pixel_color(
        self.lock_win_id, self.lock_x, self.lock_y
    )
    if not color:
      return

    self.ui_callback("lock_color", color)
    R, _, _ = color

    if R < 10:
      self.ui_callback("lock", "Ожидание боя | На /follow")
      return

    if near(R, 20):
      self.lock_lifetap_remaining = 0
      self.send_lock_key("{F6}", "💀 ХП <= 5%! СТОП + ЛИК СМЕРТИ!", 300)
      return

    if near(R, 40):
      if self.lock_lifetap_remaining <= 0:
        self.lock_lifetap_remaining = random.randint(2, 4)

    if near(R, 50):
      self.lock_lifetap_remaining = 0

    if self.lock_lifetap_remaining > 0 and (near(R, 40) or near(R, 45)):
      sent = self.send_lock_key(
          "{F7}",
          f"🩸 Жизнеотвод (осталось: {self.lock_lifetap_remaining})",
          1500,
      )
      if sent:
        self.lock_lifetap_remaining -= 1
      return

    # Новые коды позиционирования Лока:
    if near(R, 210):
      self.stop_movement(self.lock_win_id, "lock")
      return
    elif near(R, 220):
      self.face_target_lock()
      return
    elif near(R, 230):
      self.send_lock_key("{Numpad6}", "🧱 Стена (LoS)! Бегу к танку", 600)
      return
    elif near(R, 250):
      self.send_lock_key("{Numpad6}", "🏃 Возврат на /follow focus", 800)
      return

    if self.lock_aoe_mode and 60 <= R <= 180:
      self.send_lock_key("{Numpad1}", "💥 АОЕ: Семя порчи", 900)
      return

    if near(R, 60):
      self.send_lock_key("{F8}", "🔥 ОЖОГ ДУШИ (Истребление!)", 500)
    elif near(R, 80):
      self.send_lock_key("{F9}", "😈 Метаморфоза (Бурст)", 1000)
    elif near(R, 100):
      self.send_lock_key("{F10}", "⚡ Проклятие стихий", 900)
    elif near(R, 120):
      self.send_lock_key("{F11}", "🔥 Жертвенный огонь", 1400)
    elif near(R, 140):
      self.send_lock_key("{F12}", "🟣 Порча", 900)
    elif near(R, 160):
      self.send_lock_key("{Numpad2}", "🌑 Стрела Тьмы", 700)