# Промти для першої партії кат-сцен

Два арти, які перевикористаються в багатьох кадрах, тож їх варто
зафіксувати першими: **старий мольфар зі спини** і **хата зовні**.

---

## Про стиль

Усе в грі мальоване — і персонажі, і фони. Різниця між ними тільки в
щільності письма: фігури написані тугіше й детальніше
(`mavka.png`, `forest_warden_1.png`), пейзаж — вільнішим мазком із
видимою фактурою (`menu_backdrop_day.png`).

Це не конфлікт, і перевіряти не треба — портрети вже стоять на
мальованому інтер'єрі хати й тримаються там добре.

Тому мольфар пишеться **як решта персонажів**, а хата — **як фон меню**.
Нижче в кожному промті письмо задане відповідно; не плутай їх місцями.

Для генератора відео це ще й зручно: мазок пробачає артефакти руху
куди краще, ніж фотографія, — на пейзажі їх майже не видно.

---

## 1. Мольфар зі спини

**Чому саме зі спини, а не портрет.** Не тільки тому, що так попросили —
так правильно. Гравець *є* ним, і обличчя сперечалося б із цим. Але
головне попереду: у повній версії він зник, і його шукає спадкоємець.
Поки обличчя нема, він лишається відсутністю, а не персонажем. Щойно
покажемо — стане просто дідом, і зникнення втратить вагу.

Тому зі спини він має бути **завжди**, у всіх кадрах. Жодного профілю,
жодного повороту голови через плече.

**Його не обов'язково вклеювати у відео.** Оскільки він вирізка на
чорному, як усі персонажі, рушій може покласти його шаром поверх
готового ролика з хатою — із ледь помітним `SWAY`, наче вітер у полі
сердака. Це дає дві переваги: не треба генерувати «мольфар + хата»
одним роликом і сподіватися, що він вийде тим самим чоловіком, і один
його арт обслуговує скільки завгодно кадрів. Генеруй фігуру окремо,
краєвиди окремо.

**Промт (референс для вирізання, на чорному):**

```
Full-body view from directly behind of a very old, frail Carpathian
Hutsul mountain healer, about eighty years old.

His posture carries his whole age, because his face will never be seen.
His upper back is strongly curved forward into a pronounced hunch. His
shoulders are rounded and pulled in, narrow and bony, and his head sits
low between them with the neck craning forward. His whole weight rests
on his right leg; the left knee is bent and the left heel is lifted
clear off the ground. One shoulder hangs visibly lower than the other.
He is thin, and the coat is plainly too big for him — it hangs loose and
empty off his frame rather than fitting.

Long, unkempt, straggling white hair hangs past his collar from beneath
a battered dark felt hat, its brim soft and drooping unevenly. He wears
a knee-length dark brown wool overcoat, old and sun-faded, the nap worn
bald at the shoulders, one elbow crudely patched, the hem frayed and
stained with dried mud. Faded red and ochre woven trim runs along the
hem and cuffs. A wide leather belt with tarnished brass studs. A
battered leather shoulder bag on a long strap at his right hip. Several
small bundles of dried herbs are tied to his belt and hang against his
hip.

Slung diagonally across his back, clearly visible, a long wooden
axe-staff: its dark shaft runs from above his left shoulder down to his
right hip, and its small flat metal axe head stands out plainly against
the coat above the left shoulder. Heavy, cracked, mud-caked leather
boots.

Both arms hang down and slightly forward, his hands brought together in
front of his stomach and completely concealed behind his torso from this
rear view. No hands, no fingers, no wrists are visible anywhere in the
image. The overcoat's long sleeves fall past his knuckles. His elbows
read only as soft folds at his sides.

Seen strictly from behind — his face is not visible at all. Detailed
digital painting, the same tight painterly rendering as the other
character portraits, muted earth palette of browns and ochres, soft even
light with no hard shadows. Plain flat background, nothing else in the
frame. Full figure from hat to boots, centred, vertical composition.
```

**Негативне:** `hands, fingers, visible hands, hand holding object,
arms outstretched, straight back, upright posture, military stance,
symmetrical stance, feet together, broad shoulders, young man,
middle-aged, clean new clothing, tidy, face, facial features, looking
over shoulder, profile view, three-quarter view, turning head,
photograph, 3d render, text, watermark, modern clothing`

**Чому руки заховані.** Генератор майже завжди псує кисті, а тут їх
можна прибрати чесно, не вигадуючи пози: зі спини складені перед собою
руки затуляє власний тулуб. Тому бартка й переїхала за спину на
ремінець — у руці вона вимагала б видимої кисті, а на спині лишається в
силуеті задарма.

Якщо генератор усе одно вилазить кистю з-за боку — додай у промт
`his arms are not visible at all, only the coat's silhouette`. Останній
засіб: кадрувати по пояс, бо для кадрів 1 і 3 цього вистачає.

**Що тут не випадкове:**

- **Бартка** (топірець на довгому держаку) — найвпізнаваніша річ
  мольфара, і єдина, що читається зі спини з першого погляду. Без неї
  він просто старий у плащі. За спиною на ремінці, а не в руці, —
  щоб не доводилося малювати кисть.
- **Тобівка** — шкіряна наплічна торба з латунню, гуцульська й доречна
  саме для нього.
- **Сердак** із тканою крайкою по подолу — те, що в'яже його з рештою
  села, бо червоно-вохриста ткана смуга вже є в портретах лісника й
  вівчаря.
- **Згорблений, вага на одну ногу, п'ята відірвана від землі** — вік
  має читатися з силуету, бо обличчя нема. Перша спроба провалилася
  саме тут: на `slightly stooped` генератор не зважає взагалі й ставить
  симетричну фігуру з рівними плечима, а це постава сорокарічного. Тому
  тепер поза описана окремим абзацом, із конкретикою — вигин спини,
  висота плечей, зігнуте коліно, завелике пальто на худих плечах.
- **Витертий, латаний, у болоті** — інакше виходить заможний селянин у
  добрій одежі, а не чоловік, до якого піднімаються в гору. Пучки
  сухого зілля на поясі роблять найбільше: їх не носить більше ніхто.

### Якщо бартка знову зникне

Перша спроба її просто викинула, хоч вона й була в промті. Тепер опис
розгорнутий — куди йде держак, де головка, на тлі чого вона видна.
Якщо генератор усе одно її не малює, це єдина річ, за яку варто
перегенерувати ще кілька разів: без неї силует не відрізняється від
будь-якого діда в сердаку, а відрізнятися він мусить із першого
погляду.

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
