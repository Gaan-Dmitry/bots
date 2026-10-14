import customtkinter as ctk
import logging
import keyboard
from config import THEME
from win_api import get_mouse_client_pos, make_window_noactivate
from bot_engine import BotEngine
from logging_setup import configure_logging


class PBotHUD(ctk.CTk):
    def __init__(self):
        super().__init__()

        self.title("PBot v7.0 CyberHUD")
        self.full_height = 148
        self.mini_height = 38
        self.is_minimized = False

        self.geometry(f"450x{self.full_height}+350+8")
        self.overrideredirect(True)
        self.attributes("-topmost", True)
        # Полупрозрачный режим (0.75 по умолчанию)
        self.attributes("-alpha", 0.75)

        self.configure(fg_color=THEME["transparent_key"])
        self.attributes("-transparentcolor", THEME["transparent_key"])

        self._drag_x = 0
        self._drag_y = 0

        self.shell = ctk.CTkFrame(
            self,
            fg_color=THEME["bg"],
            border_color=THEME["border_idle"],
            border_width=2,
            corner_radius=14
        )
        self.shell.pack(fill="both", expand=True, padx=2, pady=2)

        self.engine = BotEngine(ui_callback=self.update_ui_safe)

        self._build_header()
        self._build_body()
        self._register_hotkeys()

        # Включаем защиту от перехвата фокуса (как в AHK!)
        self.after(100, lambda: make_window_noactivate(self))

        # Плавная подсветка при наведении курсора
        self.bind("<Enter>", lambda e: self.attributes("-alpha", 0.92))
        self.bind("<Leave>", lambda e: self.attributes("-alpha", 0.75))

    # =========================================================================
    # ВЕРХНЯЯ ПАНЕЛЬ (ШАПКА)
    # =========================================================================
    def _build_header(self):
        self.header = ctk.CTkFrame(self.shell, fg_color="transparent", height=30)
        self.header.pack(fill="x", padx=12, pady=(6, 2))

        # Светящаяся точка статуса
        self.status_dot = ctk.CTkLabel(
            self.header,
            text="●",
            font=("Segoe UI", 16, "bold"),
            text_color="#F38BA8",
            width=16
        )
        self.status_dot.pack(side="left", padx=(0, 4))

        # Заголовок
        self.title_lbl = ctk.CTkLabel(
            self.header,
            text="PBOT v7.0",
            font=("Segoe UI", 13, "bold"),
            text_color=THEME["text"]
        )
        self.title_lbl.pack(side="left")

        # Бейдж статуса (ПАУЗА / АКТИВЕН)
        self.badge_lbl = ctk.CTkLabel(
            self.header,
            text="ПАУЗА [F4]",
            font=("Consolas", 11, "bold"),
            fg_color="#27273A",
            text_color="#A6ADC8",
            corner_radius=6,
            padx=8,
            pady=1
        )
        self.badge_lbl.pack(side="left", padx=10)

        # Кнопка закрытия [×]
        self.btn_close = ctk.CTkButton(
            self.header,
            text="×",
            width=24,
            height=22,
            corner_radius=6,
            font=("Segoe UI", 14, "bold"),
            fg_color=THEME["btn_neutral"],
            hover_color=THEME["btn_pause"],
            text_color=THEME["text"],
            command=self.destroy
        )
        self.btn_close.pack(side="right", padx=(4, 0))

        # Кнопка сворачивания в полоску [—]
        self.btn_min = ctk.CTkButton(
            self.header,
            text="—",
            width=24,
            height=22,
            corner_radius=6,
            font=("Segoe UI", 12, "bold"),
            fg_color=THEME["btn_neutral"],
            hover_color=THEME["btn_neutral_hover"],
            text_color=THEME["text"],
            command=self._toggle_minimize
        )
        self.btn_min.pack(side="right")

        # Привязка перетаскивания к шапке
        for w in (self.header, self.status_dot, self.title_lbl, self.badge_lbl):
            w.bind("<ButtonPress-1>", self._start_move)
            w.bind("<B1-Motion>", self._on_move)

    # =========================================================================
    # ОСНОВНОЙ КОНТЕНТ (КАРТОЧКИ ХИЛА/ЛОКА + КНОПКИ)
    # =========================================================================
    def _build_body(self):
        self.body = ctk.CTkFrame(self.shell, fg_color="transparent")
        self.body.pack(fill="both", expand=True, padx=10, pady=(2, 8))

        # --- ЛЕВАЯ ЧАСТЬ: КАРТОЧКИ БОТОВ ---
        cards_col = ctk.CTkFrame(self.body, fg_color="transparent")
        cards_col.pack(side="left", fill="both", expand=True, padx=(0, 8))

        # 1. Карточка Друида
        self.druid_card = ctk.CTkFrame(
            cards_col,
            fg_color=THEME["card"],
            border_color=THEME["card_border"],
            border_width=1,
            corner_radius=8,
            height=44
        )
        self.druid_card.pack(fill="x", pady=(0, 6))
        self.druid_card.pack_propagate(False)

        # Живой индикатор цвета пикселя Друида
        self.druid_swatch = ctk.CTkFrame(
            self.druid_card,
            width=26,
            height=26,
            corner_radius=6,
            fg_color="#11111B",
            border_color=THEME["druid"],
            border_width=1
        )
        self.druid_swatch.pack(side="left", padx=(8, 8), pady=8)

        druid_info_box = ctk.CTkFrame(self.druid_card, fg_color="transparent")
        druid_info_box.pack(side="left", fill="both", expand=True, pady=4)

        druid_top = ctk.CTkFrame(druid_info_box, fg_color="transparent")
        druid_top.pack(fill="x")

        ctk.CTkLabel(
            druid_top,
            text="🌿 ДРУИД [F3]",
            font=("Segoe UI", 10, "bold"),
            text_color=THEME["druid"]
        ).pack(side="left")

        self.druid_rgb_lbl = ctk.CTkLabel(
            druid_top,
            text="G:0 B:0",
            font=("Consolas", 10),
            text_color=THEME["subtext"]
        )
        self.druid_rgb_lbl.pack(side="right", padx=(0, 8))

        self.druid_lbl = ctk.CTkLabel(
            druid_info_box,
            text="Наведи на цветной квадрат в WoW и жми F3",
            font=("Segoe UI", 12, "bold"),
            text_color=THEME["text"],
            anchor="w"
        )
        self.druid_lbl.pack(fill="x")

        # 2. Карточка Чернокнижника
        self.lock_card = ctk.CTkFrame(
            cards_col,
            fg_color=THEME["card"],
            border_color=THEME["card_border"],
            border_width=1,
            corner_radius=8,
            height=44
        )
        self.lock_card.pack(fill="x")
        self.lock_card.pack_propagate(False)

        # Живой индикатор цвета пикселя Лока
        self.lock_swatch = ctk.CTkFrame(
            self.lock_card,
            width=26,
            height=26,
            corner_radius=6,
            fg_color="#11111B",
            border_color=THEME["warlock"],
            border_width=1
        )
        self.lock_swatch.pack(side="left", padx=(8, 8), pady=8)

        lock_info_box = ctk.CTkFrame(self.lock_card, fg_color="transparent")
        lock_info_box.pack(side="left", fill="both", expand=True, pady=4)

        lock_top = ctk.CTkFrame(lock_info_box, fg_color="transparent")
        lock_top.pack(fill="x")

        ctk.CTkLabel(
            lock_top,
            text="🔥 ДЕМОН-ЛОК [Shift+F3]",
            font=("Segoe UI", 10, "bold"),
            text_color=THEME["warlock"]
        ).pack(side="left")

        self.lock_rgb_lbl = ctk.CTkLabel(
            lock_top,
            text="R:0",
            font=("Consolas", 10),
            text_color=THEME["subtext"]
        )
        self.lock_rgb_lbl.pack(side="right", padx=(0, 8))

        self.lock_lbl = ctk.CTkLabel(
            lock_info_box,
            text="Наведи на цветной квадрат в WoW и жми Shift+F3",
            font=("Segoe UI", 12, "bold"),
            text_color=THEME["text"],
            anchor="w"
        )
        self.lock_lbl.pack(fill="x")

        # --- ПРАВАЯ ЧАСТЬ: КНОПКИ УПРАВЛЕНИЯ ---
        btn_col = ctk.CTkFrame(self.body, fg_color="transparent")
        btn_col.pack(side="right", fill="y")

        self.btn_toggle = ctk.CTkButton(
            btn_col,
            text="▶ СТАРТ (F4)",
            width=118,
            height=28,
            corner_radius=7,
            font=("Segoe UI", 11, "bold"),
            fg_color=THEME["btn_start"],
            hover_color=THEME["btn_start_hover"],
            command=self.engine.toggle_bot
        )
        self.btn_toggle.pack(pady=(0, 5))

        self.btn_aoe = ctk.CTkButton(
            btn_col,
            text="🎯 РЕЖИМ: СОЛО",
            width=118,
            height=28,
            corner_radius=7,
            font=("Segoe UI", 11, "bold"),
            fg_color=THEME["aoe_off"],
            hover_color=THEME["btn_neutral_hover"],
            border_color=THEME["card_border"],
            border_width=1,
            command=self.engine.toggle_aoe_mode
        )
        self.btn_aoe.pack(pady=(0, 5))

        self.btn_unstuck = ctk.CTkButton(
            btn_col,
            text="🦘 Прыжок (Alt+X)",
            width=118,
            height=26,
            corner_radius=7,
            font=("Segoe UI", 11),
            fg_color=THEME["btn_neutral"],
            hover_color=THEME["btn_neutral_hover"],
            border_color=THEME["card_border"],
            border_width=1,
            command=self.engine.unstuck_jump
        )
        self.btn_unstuck.pack()

    # =========================================================================
    # СВОРАЧИВАНИЕ И ПЕРЕТАСКИВАНИЕ ОКНА
    # =========================================================================
    def _toggle_minimize(self):
        self.is_minimized = not self.is_minimized
        x, y = self.winfo_x(), self.winfo_y()
        if self.is_minimized:
            self.body.pack_forget()
            self.geometry(f"450x{self.mini_height}+{x}+{y}")
            self.btn_min.configure(text="▢")
        else:
            self.geometry(f"450x{self.full_height}+{x}+{y}")
            self.body.pack(fill="both", expand=True, padx=10, pady=(2, 8))
            self.btn_min.configure(text="—")

    def _start_move(self, event):
        self._drag_x = event.x_root - self.winfo_x()
        self._drag_y = event.y_root - self.winfo_y()

    def _on_move(self, event):
        x = event.x_root - self._drag_x
        y = event.y_root - self._drag_y
        self.geometry(f"+{x}+{y}")

    # =========================================================================
    # БЕЗОПАСНОЕ ОБНОВЛЕНИЕ ИНТЕРФЕЙСА
    # =========================================================================
    def update_ui_safe(self, channel: str, payload):
        self.after(0, self._update_ui, channel, payload)

    def _update_ui(self, channel: str, payload):
        if channel == "druid":
            self.druid_lbl.configure(text=payload)
        elif channel == "lock":
            self.lock_lbl.configure(text=payload)
        elif channel == "druid_color":
            r, g, b = payload
            hex_color = f"#{r:02x}{g:02x}{b:02x}"
            self.druid_swatch.configure(fg_color=hex_color)
            self.druid_rgb_lbl.configure(text=f"G:{g} B:{b}")
        elif channel == "lock_color":
            r, g, b = payload
            hex_color = f"#{r:02x}{g:02x}{b:02x}"
            self.lock_swatch.configure(fg_color=hex_color)
            self.lock_rgb_lbl.configure(text=f"R:{r}")
        elif channel == "state":
            is_running = payload
            if is_running:
                self.shell.configure(border_color=THEME["border_active"])
                self.status_dot.configure(text_color=THEME["border_active"])
                self.badge_lbl.configure(text="АКТИВЕН [F4]", fg_color="#1E3A2F", text_color=THEME["druid"])
                self.btn_toggle.configure(
                    text="⏸ ПАУЗА (F4)",
                    fg_color=THEME["btn_pause"],
                    hover_color=THEME["btn_pause_hover"]
                )
            else:
                self.shell.configure(border_color=THEME["border_idle"])
                self.status_dot.configure(text_color="#F38BA8")
                self.badge_lbl.configure(text="ПАУЗА [F4]", fg_color="#27273A", text_color="#A6ADC8")
                self.btn_toggle.configure(
                    text="▶ СТАРТ (F4)",
                    fg_color=THEME["btn_start"],
                    hover_color=THEME["btn_start_hover"]
                )
        elif channel == "aoe_state":
            is_aoe = payload
            if is_aoe:
                self.btn_aoe.configure(
                    text="💥 РЕЖИМ: АОЕ",
                    fg_color=THEME["aoe_on"],
                    hover_color="#E05200",
                    border_color="#FF8736"
                )
            else:
                self.btn_aoe.configure(
                    text="🎯 РЕЖИМ: СОЛО",
                    fg_color=THEME["aoe_off"],
                    hover_color=THEME["btn_neutral_hover"],
                    border_color=THEME["card_border"]
                )

    # =========================================================================
    # ГЛОБАЛЬНЫЕ ХОТКЕИ
    # =========================================================================
    def _register_hotkeys(self):
        keyboard.add_hotkey("f3", self._on_f3)
        keyboard.add_hotkey("shift+f3", self._on_shift_f3)
        keyboard.add_hotkey("f4", self.engine.toggle_bot)
        keyboard.add_hotkey("caps lock", self.engine.toggle_aoe_mode)
        keyboard.on_press_key(45, self._on_key_x, suppress=False)

    def _on_f3(self):
        if keyboard.is_pressed("shift"):
            return
        hwnd, x, y = get_mouse_client_pos()
        if hwnd:
            self.engine.bind_druid(hwnd, x, y)

    def _on_shift_f3(self):
        hwnd, x, y = get_mouse_client_pos()
        if hwnd:
            self.engine.bind_lock(hwnd, x, y)

    def _on_key_x(self, _event):
        if keyboard.is_pressed("alt"):
            self.engine.unstuck_jump()
        else:
            self.engine.focus_and_follow()


if __name__ == "__main__":
    configure_logging()
    try:
        app = PBotHUD()
        app.mainloop()
    except Exception:
        logging.getLogger(__name__).exception("PBot завершился из-за необработанной ошибки")
        raise