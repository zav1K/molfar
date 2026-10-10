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
Seen from directly behind: a very old, frail, shrunken Carpathian
Hutsul mountain healer of about eighty, pausing on a slope.

His posture carries his whole age, because his face will never be seen.
His upper back is bent into a heavy hump between the shoulder blades,
so pronounced that the line of his back is a curve, never a straight
line. His head is sunk low between rounded shoulders and pushed
forward, almost no neck visible. His whole weight is on his right leg,
which is straight; his left knee is clearly bent and his left heel is
lifted well clear of the ground, the toe only just touching. His right
shoulder hangs noticeably lower than his left. He is small and thin
inside a coat several sizes too large, which hangs slack and empty off
him, collapsing in folds rather than filling out.

Long, unkempt, straggling white hair hangs past his collar from beneath
a battered dark felt hat, its brim soft and drooping unevenly. He wears
a knee-length overcoat of plain coarse homespun wool — a flat, matte,
smooth felted cloth with no pattern, no quilting and no texture of its
own, like old blanket wool. It is sun-bleached to a dull grey-brown,
the nap worn bald across the shoulders, one elbow crudely patched with
a square of mismatched cloth, the hem frayed into threads and stained
dark with dried mud. Narrow faded red and ochre woven trim runs along
the hem and cuffs. A plain worn leather belt. A scuffed leather
shoulder bag on a long strap at his right hip. Several small bundles of
dried herbs are tied to his belt and hang against his hip. His trousers
are plain undyed linen, baggy and creased; his boots are plain scuffed
leather, cracked and caked with dried mud.

Across the upper back of the coat, spanning from shoulder to shoulder
like a yoke, a broad woven band of a continuous zigzag wave motif in
faded red and ochre thread — the same weaving as the trim at the hem,
worked into the cloth itself, flat and soft, not an applied object.
It is the only ornament on him; everything else is plain.

Both arms hang down and slightly forward, his hands brought together in
front of his stomach and completely concealed behind his torso from this
rear view. No hands, no fingers, no wrists are visible anywhere in the
image. The overcoat's long sleeves fall past his knuckles. His elbows
read only as soft folds at his sides.

Seen strictly from behind — his face is not visible at all. Detailed
digital painting, the same tight painterly rendering as the other
character portraits, muted earth palette of browns and ochres, soft even
light with no hard shadows. Plain flat background, nothing else in the
frame. He is small in the frame, off balance, and not centred — this is
a moment, not a costume sheet.
```

**Негативне:** `hands, fingers, visible hands, hand holding object,
arms outstretched, straight back, upright posture, military stance,
symmetrical stance, feet together, both heels on the ground, broad
shoulders, tall, young man, middle-aged, clean new clothing, tidy,
ornate, embroidered all over, scales, scaled texture, fish scale
pattern, quilted, padded, reptile skin, armour, leather armour,
repeating fabric pattern, character reference sheet, T-pose, face,
facial features, looking over shoulder, profile view, three-quarter
view, turning head, photograph, 3d render, text, watermark, modern
clothing`

**Чому руки заховані.** Генератор майже завжди псує кисті, а тут їх
можна прибрати чесно, не вигадуючи пози: зі спини складені перед собою
руки затуляє власний тулуб. Перевірено — працює, у першій спробі кистей
не видно взагалі. Побічний наслідок: нічого, що тримають у руці, він
нести не може — ще одна причина, чому знак переїхав на спину сердака.

Якщо генератор усе одно вилазить кистю з-за боку — додай у промт
`his arms are not visible at all, only the coat's silhouette`. Останній
засіб: кадрувати по пояс, бо для кадрів 1 і 3 цього вистачає.

**Що тут не випадкове:**

- **Кривулька на спині сердака** — замість бартки. Бартку з першої
  спроби прибрали: довга діагональ через м'яко написану фігуру читалася
  як приклеєний реквізит. Але щось мусить відрізняти його силует від
  будь-якого селянина, і спина — найбільша видима площина в кадрі зі
  спини, тож знак іде туди.

  Кривулька — справжній гуцульський оберіг, яким крили сволок і
  одвірки, **щоб лихе не переступило поріг** (`data/sigils/zigzag_ward.tres`).
  Розділ називається «Поріг», і цей знак носить на спині чоловік, який
  щоночі вирішує, кого пускати. Це той самий знак, який гравець ріже
  ножем у грі, — а в повній версії його впізнає спадкоємець.

  Вона вткана в полотно, а не причеплена, тож із силуету нічого не
  стирчить — саме те, чим не влаштувала бартка.

  **Якщо зі спини він усе одно читається як звичайний селянин**, є
  сильніший варіант: не смуга через плечі, а **сонячна спіраль між
  лопатками** (`data/sigils/spiral_ward.tres`) — помітніша з першого
  погляду, але ризикує виглядати як нашивка. Починав би зі смуги.
  ```
  ...and between his shoulder blades a single large woven spiral motif
  in faded red and ochre thread, worked into the cloth of the coat.
  ```
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

### Що вже працює — не чіпати

- **Руки.** Жодного покрученого пальця за дві спроби. Трюк «складені
  перед собою, затулені тулубом» надійний.
- **Зілля на поясі.** Найсильніший сигнал «мольфар» у кадрі,
  спрацювало з першого разу.
- **Кривулька** на плечах і подолі лягла добре.

### Якщо постава знову вийде рівною

За дві спроби генератор двічі повернув симетричну стійку. Винні не
слова про горб, а **композиція**: `standing still, full figure,
centred, vertical composition` — це формулювання референс-аркуша, і
воно тягне в симетрію сильніше, ніж будь-який опис пози. Тому ці слова
прибрані, а в негативне додані `character reference sheet`, `T-pose`,
`symmetrical stance`, `both heels on the ground`.

Якщо й це не допоможе — **най іде**. Крок знімає симетрію сам собою, і
для кат-сцени фігура, що повільно йде вгору стежкою або в туман,
корисніша за ту, що стоїть:

```
...caught mid-stride, walking slowly away from the viewer up the
slope, his left foot forward and flat, his right heel lifted high
behind him, the coat swinging open at the hem with the movement.
```

Мінус один: вирізку в русі важче класти шаром поверх відео — вона
проситься бути анімованою. Тож спершу варто добити стійку.

### Про лускату фактуру

Друга спроба вкрила все — пальто, штани, чоботи, капелюх — однаковим
лускатим стьобаним візерунком. Це типове «деталізування» генератора, і
воно читається як обладунок, а не вовна. Лікується двома боками: у
промті прямо сказано `plain coarse homespun wool, flat matte smooth
felted cloth with no pattern, no quilting, like old blanket wool`, а в
негативному — `scales, fish scale pattern, quilted, reptile skin,
armour, repeating fabric pattern`.

### Про «він виглядає заможним»

Друга спроба вийшла ошатнішою за першу: оздоблення всюди, нічого не
зношене. Тепер у промті кривулька названа **єдиною оздобою** («It is
the only ornament on him; everything else is plain»), а решта речей
прямо описана як проста: некрашене полотно штанів, простий ремінь,
потерті чоботи. Латка на лікті, витерті плечі й болото на подолі —
саме те, чого двічі не було.

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
