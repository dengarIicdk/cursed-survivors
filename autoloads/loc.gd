extends Node

## Tiny runtime localisation layer.
##
## English source strings are the keys, so code stays readable:
##     UIKit.label(Loc.s("SOULS"), ...)  ->  "ДУШИ" in Russian.
## Anything missing from the RU table falls back to the English original, which
## makes partial translation harmless instead of fatal.

signal language_changed

const LANGS: Array[String] = ["en", "ru"]

## Display names for the language picker (never translated).
const LANG_LABELS := {
	"en": "English",
	"ru": "Русский",
}

const RU: Dictionary = {
	# ---- title screen ----
	"CURSED SURVIVORS": "ПРОКЛЯТЫЕ ВЫЖИВШИЕ",
	"SURVIVE THE NIGHT   ✦   HARVEST SOULS": "ВЫЖИВИ В НОЧИ   ✦   СОБИРАЙ ДУШИ",
	"BEGIN THE HUNT": "НАЧАТЬ ОХОТУ",
	"CURSED SHOP": "ПРОКЛЯТАЯ ЛАВКА",
	"SETTINGS": "НАСТРОЙКИ",
	"QUIT": "ВЫХОД",
	"RESET": "СБРОС",
	"CANCEL": "ОТМЕНА",
	"ERASE ALL PROGRESS?": "СТЕРЕТЬ ВЕСЬ ПРОГРЕСС?",
	"Souls, unlocked survivors, blessings and maps will be lost forever.":
		"Души, открытые герои, благословения и карты будут потеряны навсегда.",
	"ERASE EVERYTHING": "СТЕРЕТЬ ВСЁ",
	"SOULS  {n}": "ДУШИ  {n}",
	"{n} SOULS": "{n} ДУШ",
	"LOCKED  •  200 SOULS": "ЗАКРЫТО  •  200 ДУШ",
	"SELECTED": "ВЫБРАН",
	"LOCKED": "ЗАКРЫТО",
	"BEST  {n}": "РЕКОРД  {n}",
	# ---- survivors ----
	"Hexblade": "Клинок Скверны",
	"Ironclad": "Железный",
	"Wraithborn": "Дитя Тени",
	"Stormcaller": "Зов Бури",
	"Dark Mage": "Тёмный маг",
	"Warrior": "Воин",
	"Rogue": "Разбойник",
	"Shaman": "Шаман",
	# ---- maps ----
	"Cursed Graveyard": "Проклятое кладбище",
	"Infernal Depths": "Адские глубины",
	# ---- HUD ----
	"LV {n}": "УР {n}",
	"BOSS": "БОСС",
	# ---- level up ----
	"LEVEL UP": "НОВЫЙ УРОВЕНЬ",
	"CHOOSE YOUR CURSE": "ВЫБЕРИ СВОЁ ПРОКЛЯТИЕ",
	"press  1  ·  2  ·  3": "нажми  1  ·  2  ·  3",
	"WEAPON  •  UPGRADE": "ОРУЖИЕ  •  УЛУЧШЕНИЕ",
	"NEW  WEAPON": "НОВОЕ ОРУЖИЕ",
	"PASSIVE": "ПАССИВКА",
	"UNLOCK": "ОТКРЫТО",
	"EVOLVE": "ЭВОЛЮЦИЯ",
	# ---- game over ----
	"YOU DIED": "ВЫ ПОГИБЛИ",
	"NIGHT SURVIVED": "НОЧЬ ПЕРЕЖИТА",
	"TIME SURVIVED": "ПРОДЕРЖАЛСЯ",
	"SOULS HARVESTED": "СОБРАНО ДУШ",
	"LEVEL REACHED": "ДОСТИГНУТ УРОВЕНЬ",
	"+{n} SOULS": "+{n} ДУШ",
	"PLAY AGAIN": "ЕЩЁ РАЗ",
	"MAIN MENU": "ГЛАВНОЕ МЕНЮ",
	# ---- pause ----
	"PAUSED": "ПАУЗА",
	"RESUME": "ПРОДОЛЖИТЬ",
	"RESTART": "ЗАНОВО",
	"TIME": "ВРЕМЯ",
	"SOULS": "ДУШИ",
	"LEVEL": "УРОВЕНЬ",
	# ---- shop ----
	"THE CURSED SHOP": "ПРОКЛЯТАЯ ЛАВКА",
	"UNLOCK SURVIVORS": "ОТКРЫТЬ ВЫЖИВШИХ",
	"ETERNAL BLESSINGS": "ВЕЧНЫЕ БЛАГОСЛОВЕНИЯ",
	"RETURN": "НАЗАД",
	"OWNED": "КУПЛЕНО",
	"MAX": "МАКС",
	"BRAWLER  •  Shield Aura": "БОЕЦ  •  Аура щита",
	"REAPER  •  Shadow Step": "ЖНЕЦ  •  Шаг в тень",
	"ARCANIST  •  Chain Lightning": "ЧАРОДЕЙ  •  Цепь молний",
	"Max HP": "Макс. жизни",
	"Damage": "Урон",
	"Move Speed": "Скорость",
	"+25 maximum life": "+25 к максимуму жизни",
	"+5% all damage": "+5% ко всему урону",
	"+3% movement speed": "+3% к скорости",
	# ---- bosses ----
	"Lich King": "Король-лич",
	"Giant Troll": "Гигантский тролль",
	"Necromancer": "Некромант",
	"Shadow Drake": "Теневой дрейк",
	# ---- settings ----
	"AUDIO": "ЗВУК",
	"DISPLAY": "ЭКРАН",
	"LANGUAGE": "ЯЗЫК",
	"Master": "Общая громкость",
	"Music": "Музыка",
	"SFX": "Эффекты",
	"Resolution": "Разрешение",
	"Window Mode": "Режим окна",
	"WINDOWED": "В окне",
	"BORDERLESS": "Полноэкранный в окне",
	"FULLSCREEN": "Полноэкранный",
	"BACK": "НАЗАД",
	"CHANGE LANGUAGE": "СМЕНИТЬ ЯЗЫК",
	# ---- weapons ----
	"Arcane Orbs": "Тайные сферы",
	"Chaos Bolt": "Хаос-стрела",
	"Blade Aura": "Аура клинков",
	"Sword Splash": "Рассекающий удар",
	"Shield Bash": "Удар щитом",
	"Shadow Daggers": "Тени-кинжалы",
	"Fan of Knives": "Веер клинков",
	"Lightning Chain": "Цепь молний",
	"Frost Nova": "Ледяная вспышка",
	"Chaos Vortex": "Вихрь хаоса",
	"Void Requiem": "Реквием пустоты",
	"Bloodreaver": "Кровопуск",
	"Bulwark Eclipse": "Затмение бастиона",
	"Soul Reaper": "Жнец душ",
	"Crimson Waltz": "Алый вальс",
	"Thunderstorm": "Гроза",
	"Absolute Zero": "Абсолютный ноль",
	"Juggernaut Spin": "Вращение джаггернаута",
	"Orbs orbit you, shredding anything they touch": "Сферы вращаются вокруг, кромсая всё на пути",
	"THE RING CLOSES": "КОЛЬЦО СЖИМАЕТСЯ",
	"RING {t}": "КОЛЬЦО {t}",
	"Break through!": "ПРОРЫВАЙСЯ!",
	"No way out": "ВЫХОДА НЕТ",
	"The ring broke": "КОЛЬЦО ПРОРВАНО",
	"Homing bolts that burst into violet fire": "Самонаводящиеся стрелы, взрывающиеся фиолетовым огнём",
	"Spinning blades circle you without rest": "Вращающиеся клинки кружат вокруг без отдыха",
	"Orbiting blades that fly out and come back": "Клинки кружат вокруг и вылетают бумерангом",
	"Heavy cleave that carves a wide arc ahead": "Тяжёлый удар, рассекающий широкую дугу",
	"Slam the ground and blast the crowd away": "Удар по земле, разметающий толпу",
	"Homing daggers hunt down the nearest wretches": "Кинжалы сами находят ближайших врагов",
	"A ring of knives thrown in every direction": "Кольцо клинков во все стороны",
	"Arcs that leap from victim to victim": "Разряды, перескакивающие с врага на врага",
	"Frost ring that freezes the ring around you": "Морозное кольцо, замораживающее всё вокруг",
	"Add to your arsenal": "Добавить в арсенал",
	"1 orbiting arcane orb": "1 сфера на орбите",
	"2 orbiting arcane orbs": "2 сферы на орбите",
	"3 orbiting arcane orbs": "3 сферы на орбите",
	"Orbs grow larger (+4px radius)": "Сферы становятся больше (+4px)",
	"Orbs gain homing — ready to evolve!": "Сферы самонаводятся — готово к эволюции!",
	"Spinning blade aura (60px radius)": "Аура вращающихся клинков (радиус 60)",
	"Radius increased to 80px": "Радиус увеличен до 80",
	"+2 blades (6 total)": "+2 клинка (всего 6)",
	"Knockback doubled": "Отбрасывание удвоено",
	"Shockwaves on critical hits — ready to evolve!": "Ударные волны при критах — готово к эволюции!",
	"Blades orbit you and fly out as boomerangs": "Клинки кружат вокруг и вылетают бумерангами",
	"Wider orbit (80px) and longer flights": "Орбита шире (80), полёт дальше",
	"Two boomerangs launched at once": "Два бумеранга за раз",
	"Boomerangs detonate on crits — ready to evolve!": "Бумеранги взрываются при крите — готово к эволюции!",
	"A homing bolt that bursts on impact": "Самонаводящаяся стрела с подрывом",
	"Two bolts per cast": "Две стрелы за каст",
	"Burst radius and damage up": "Радиус взрыва и урон выше",
	"Three bolts, faster casting": "Три стрелы, быстрее каст",
	"Bolts pierce and warp space — ready to evolve!": "Стрелы пробивают и искажают пространство — готово к эволюции!",
	"6 knives thrown in every direction": "6 клинков во все стороны",
	"8 knives per volley": "8 клинков за залп",
	"Knives pierce 2 enemies": "Клинки пробивают 2 врагов",
	"Faster volleys (1.5s)": "Залпы чаще (1.5 с)",
	"Knives carry poison — ready to evolve!": "Клинки отравляют — готово к эволюции!",
	"A ring of frost that freezes nearby enemies": "Морозное кольцо, замораживающее врагов рядом",
	"Wider ring (150px)": "Кольцо шире (150)",
	"Freeze lasts longer (0.9s)": "Заморозка дольше (0.9 с)",
	"Two rings erupt at once": "Два кольца одновременно",
	"Ring damage up — ready to evolve!": "Урон кольца выше — готово к эволюции!",
	"Lightning chains between 3 enemies": "Молния перескакивает между 3 врагами",
	"Chains to 5 enemies": "До 5 врагов в цепи",
	"Chain range +50px": "Дальность цепи +50",
	"25% chance to stun enemies": "25% шанс оглушить врага",
	"Leaves electrified zones — ready to evolve!": "Оставляет электризованные зоны — готово к эволюции!",
	"3 homing shadow daggers per burst": "3 тени-кинжала за залп",
	"Faster cooldown (1.2s)": "Быстрее перезарядка (1.2 с)",
	"5 daggers per burst": "5 кинжалов за залп",
	"Daggers pierce through 2 enemies": "Кинжалы пробивают 2 врагов",
	"3 poison stacks on hit — ready to evolve!": "3 стака яда при попадании — готово к эволюции!",
	"Shockwave slam that staggers nearby enemies": "Удар с волной, оглушающий врагов рядом",
	"Larger blast (130px)": "Взрыв больше (130)",
	"Longer stagger (0.7s)": "Дольше оглушение (0.7 с)",
	"Two slams per cast": "Два удара за каст",
	"Slams heal you a little — ready to evolve!": "Удары немного лечат — готово к эволюции!",
	"MAPS": "ЛОКАЦИИ",
	"Frozen halls beneath the earth — deadlier foes, richer souls":
		"Ледяные залы под землёй — враги злее, души богаче",
	"Wide cleave in the facing direction": "Широкий удар в направлении взгляда",
	"Longer reach (160px) and heavier blow": "Дальше (160) и сильнее",
	"Wider arc (150 degrees)": "Дуга шире (150°)",
	"Second cut follows the first": "Второй удар следует за первым",
	"Cleaves heal a little — ready to evolve!": "Удары немного лечат — готово к эволюции!",
	# ---- passives ----
	"Bloodstone": "Кровавый камень",
	"Iron Heart": "Железное сердце",
	"Quicksilver Boots": "Сапоги ртути",
	"Grimoire": "Гримуар",
	"Shadow Cloak": "Плащ тени",
	"Soul Lantern": "Фонарь душ",
	"Cursed Ring": "Проклятое кольцо",
	"Phoenix Feather": "Перо феникса",
	"Time Shard": "Осколок времени",
	"Leech Crown": "Корона пиявки",
	"Lifesteal 2% of damage dealt (max 6%)": "Вампиризм 2% от урона (макс. 6%)",
	"+50 maximum HP": "+50 к максимуму жизни",
	"+20% movement speed": "+20% к скорости",
	"+15% all damage": "+15% ко всему урону",
	"8% dodge chance": "8% шанс уклонения",
	"Double XP radius": "Двойной радиус сбора опыта",
	"+50% damage, -20% HP": "+50% урона, -20% жизни",
	"Revive once with 50% HP": "Возрождение один раз с 50% жизни",
	"-15% all cooldowns": "-15% ко всем перезарядкам",
	"Lifesteal grows with kills (max 6%)": "Вампиризм растёт с убийствами (макс. 6%)",
}


var language: String = "en"


func _ready() -> void:
	# Settings owns the persisted value and calls back into set_language().
	var settings := get_node_or_null("/root/Settings")
	if settings and settings.has_method("saved_language"):
		language = settings.saved_language()
	TranslationServer.set_locale(language)


## Translate one source string. Unknown strings pass through untouched.
func s(text: String) -> String:
	if language != "ru" or text.is_empty():
		return text
	return RU.get(text, text)


## Translate a string that already has {placeholders} substituted by `fmt`.
func f(text: String, fmt: Dictionary) -> String:
	return s(text).format(fmt)


func set_language(code: String) -> void:
	if not LANGS.has(code):
		code = "en"
	if language == code:
		return
	language = code
	TranslationServer.set_locale(code)
	language_changed.emit()
