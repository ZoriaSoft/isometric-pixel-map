extends Node
## i18n helper — EN primary for MVP web; TR ready.

var _strings: Dictionary = {
	"en": {
		"app_name": "Isometric Pixel Map",
		"tool_pen": "Pen",
		"tool_erase": "Erase",
		"tool_fill": "Fill",
		"layer_ground": "Ground",
		"layer_props": "Props",
		"export_png": "Export PNG",
		"save_json": "Save JSON",
		"load_json": "Load JSON",
		"new_map": "New map",
		"undo": "Undo",
		"redo": "Redo",
		"about": "About",
		"hint": "Paint: click-drag · Zoom: scroll or +/- · Pan: right-drag / Space+drag · Touch: 1 finger paint, 2 finger pan+pinch",
		"about_body": "Retro isometric pixel map editor. Paint a mini world, export PNG or JSON. No account needed. Free to use in the browser.",
		"about_free": "Free & open source. Paint · export · share.",
		"saved": "JSON downloaded",
		"loaded": "Map loaded",
		"exported": "PNG downloaded",
		"load_fail": "Could not load map",
		"save_fail": "Could not save",
		"export_fail": "PNG export failed",
		"grid_on": "Grid on",
		"grid_off": "Grid off",
	},
	"tr": {
		"app_name": "Isometric Pixel Map",
		"tool_pen": "Kalem",
		"tool_erase": "Silgi",
		"tool_fill": "Doldur",
		"layer_ground": "Zemin",
		"layer_props": "Üst",
		"export_png": "PNG İndir",
		"save_json": "JSON Kaydet",
		"load_json": "JSON Yükle",
		"new_map": "Yeni harita",
		"undo": "Geri al",
		"redo": "İleri al",
		"about": "Hakkında",
		"hint": "Boya: tıkla-sürükle · Zoom: tekerlek veya +/- · Kaydır: sağ tık / Space+sürükle · Dokunma: 1 parmak boya, 2 parmak kaydır+pinch",
		"about_body": "Retro izometrik pixel harita editörü. Mini dünya boya, PNG veya JSON indir. Hesap yok. Tarayıcıda ücretsiz.",
		"about_free": "Ücretsiz ve açık kaynak. Boya · dışa aktar · paylaş.",
		"saved": "JSON indirildi",
		"loaded": "Harita yüklendi",
		"exported": "PNG indirildi",
		"load_fail": "Harita yüklenemedi",
		"save_fail": "Kaydedilemedi",
		"export_fail": "PNG export başarısız",
		"grid_on": "Izgara açık",
		"grid_off": "Izgara kapalı",
	},
}


func t(key: String) -> String:
	var locale: String = str(Game.settings.get("locale", "en"))
	var bag: Dictionary = _strings.get(locale, _strings["en"])
	return str(bag.get(key, _strings["en"].get(key, key)))
