# Промти для першої партії кат-сцен

Два арти, які перевикористаються в багатьох кадрах, тож їх варто
зафіксувати першими: **старий мольфар зі спини** і **хата зовні**.

---

## Спершу — одне рішення про стиль

У проєкті зараз два різні стилі, і досі вони не зустрічалися в одному
кадрі:

| | Стиль | Приклад |
|---|---|---|
| Персонажі | майже фотореалістичні фігури на чорному | `forest_warden_1.png` |
| Екстер'єр | олійний живопис, сепія з оливковим | `menu_backdrop_day.png` |

У кат-сцені вони зустрінуться. Фотореалістична фігура на мальованому
пейзажі виглядає наклеєною — тому **обидва арти нижче в олійному
стилі**, під уже наявний фон меню.

Побічний зиск: густий мазок пробачає генераторові відео куди більше, ніж
фотореалізм. На живописі артефакти руху майже не читаються, на
фотореалістичній тканині — одразу.

---

## 1. Мольфар зі спини

**Чому саме зі спини, а не портрет.** Не тільки тому, що так попросили —
так правильно. Гравець *є* ним, і обличчя сперечалося б із цим. Але
головне попереду: у повній версії він зник, і його шукає спадкоємець.
Поки обличчя нема, він лишається відсутністю, а не персонажем. Щойно
покажемо — стане просто дідом, і зникнення втратить вагу.

Тому зі спини він має бути **завжди**, у всіх кадрах. Жодного профілю,
жодного повороту голови через плече.

**Промт (референс для вирізання, на чорному):**

```
Full-body view from directly behind of an elderly Carpathian Hutsul
mountain healer, about seventy years old, standing still. Long
iron-grey hair falling to his collar from beneath a dark worn felt hat
with a narrow brim. He wears a knee-length dark brown wool overcoat
with faded red and ochre woven trim along the hem and cuffs, over a
coarse undyed linen shirt showing at the collar. A wide leather belt
with tarnished brass studs. A leather shoulder bag on a long strap
rests at his right hip. In his left hand, held low, a long-handled
Hutsul axe-staff with a small brass-inlaid head. Heavy worn leather
boots. Slightly stooped, weight settled on one leg, the stance of a man
who has stood on slopes his whole life. Seen strictly from behind — his
face is not visible at all. Painted in thick oil brushwork, visible
brush texture, muted sepia and olive palette, warm desaturated earth
tones, soft diffused light. Plain pure black background, nothing else
in the frame. Full figure from hat to boots, centred, vertical
composition.
```

**Негативне:** `face, facial features, looking over shoulder, profile
view, three-quarter view, turning head, photorealistic skin, text,
watermark, modern clothing`

**Що тут не випадкове:**

- **Бартка** (топірець на довгому держаку) — найвпізнаваніша річ
  мольфара, і єдина, що читається зі спини з першого погляду. Без неї
  він просто старий у плащі.
- **Тобівка** — шкіряна наплічна торба з латунню, гуцульська й доречна
  саме для нього.
- **Сердак** із тканою крайкою по подолу — те, що в'яже його з рештою
  села, бо червоно-вохриста ткана смуга вже є в портретах лісника й
  вівчаря.
- **Згорблений, вага на одну ногу** — вік має читатися з силуету, бо
  обличчя нема.

---

## 2. Хата зовні

Фон меню (`menu_backdrop_day.png`) уже задає хату: ґонтовий дах, зруб,
кам'яна призьба, димар, ґанок із двома сходинками, смереки праворуч,
стежка знизу. **Це канон** — нові кадри мають бути тією самою хатою, а
не схожою.

Тому не «згенеруй хату», а **той самий будинок з іншої точки**. Якщо
генератор уміє брати зображення як референс — давай йому
`menu_backdrop_day.png`.

**Спільна частина для всіх трьох кадрів:**

```
A small Carpathian mountain hut of dark weathered log walls on a low
stone foundation, steep shingled roof, a squat stone chimney, a narrow
porch with two worn wooden steps, a single small window with a warm lit
interior. Tall spruces close on one side, misty forested ridges fading
behind. Painted in thick oil brushwork, visible brush texture, muted
sepia and olive palette, warm desaturated earth tones.
```

І далі один із трьох варіантів:

**а) Знизу, від стежки — для вступу.**

```
...Seen from below, from the footpath winding up the slope toward it,
the hut standing against a pale dawn sky. Thin smoke rising straight
from the chimney. Low mist lying in the valley below. The lower third
of the frame is quiet dark ground and path. Wide cinematic 16:9
composition, static camera, no people.
```

**б) Присмерком, з-поміж смерек — для нічних кадрів.**

```
...Seen at dusk from among the spruce trunks at the edge of the
clearing, partly screened by branches in the near foreground. The one
window glowing warm against deep blue-grey twilight. Heavier smoke from
the chimney. The lower third of the frame is dark undergrowth. Wide
cinematic 16:9 composition, static camera, no people.
```

**в) Двері зблизька, знадвору — для кадрів зі стукотом.**

```
...Close view of the hut's door from outside, at night: dark planks,
iron hinges, a bundle of dried herbs and a head of garlic hung above
the lintel, worn stone step below. Warm light leaking from the gap
beneath the door. Everything beyond the porch lost in darkness. Wide
cinematic 16:9 composition, static camera, no people.
```

---

## Для всіх кадрів однаково

- **16:9, 1920×1080.** Гра рахує кадр як 960×540 і сама вписує.
- **Нижня третина спокійна.** Підпис сидить приблизно від 72% до 90%
  висоти. Усе важливе — вище. Темний низ там на користь.
- **Камера нерухома.** Жодного наїзду й панорами — це ламає і цикл, і
  вписування кадру.
- **Жодного тексту в кадрі.**
- **Тримай сід.** Коли знайдеш вдалий кадр мольфара — лиши сід і
  референс, щоб решта кадрів була тим самим чоловіком, а не схожим.

---

## Куди вони стануть

У `data/cutscenes/intro.tres` уже п'ять кадрів із текстом:

| Кадр | Підпис (скорочено) | Що показує |
|---|---|---|
| 1 | «Хату мою видно з долини…» | **хата — варіант (а)** |
| 2 | «Сорок років вони піднімаються сюди…» | долина й село внизу |
| 3 | «Я знаю всіх на ім'я…» | **мольфар зі спини**, дивиться на долину |
| 4 | «А після заходу сонця…» | **хата — варіант (б)** |
| 5 | «Цього тижня стукати будуть частіше…» | **хата — варіант (в)** |

Тобто з двох замовлених артів закриваються чотири кадри з п'яти.

Запустити й подивитися темп можна вже зараз, без жодного ролика:
відкрити `scenes/Cutscene.tscn` і натиснути **F6**.
