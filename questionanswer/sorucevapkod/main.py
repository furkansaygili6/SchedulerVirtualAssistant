from flask import Flask, request, jsonify
import json
import difflib
import logging
from flask_cors import CORS

app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}})

logging.basicConfig(level=logging.DEBUG)

# Veri dosyasını yükle
dosya_yolu = r'C:\Users\90530\Downloads\clean_train_no_context (2).json'

# Veriyi yükler
def dosyadan_sorulari_yukle(dosya_yolu):
    with open(dosya_yolu, "r", encoding="utf-8") as dosya:
        data = json.load(dosya)
    return data["soru_cevap_listesi"]

soru_cevap_listesi = dosyadan_sorulari_yukle(dosya_yolu)

def soru_temizle(soru):
    return soru.strip().lower()

def benzer_soru_bul(soru, soru_cevap_listesi):
    temiz_soru = soru_temizle(soru)
    benzerlikler = {sc["soru"]: difflib.SequenceMatcher(None, temiz_soru, soru_temizle(sc["soru"])).ratio() for sc in soru_cevap_listesi}
    en_iyi_eslesme = max(benzerlikler, key=benzerlikler.get)
    if benzerlikler[en_iyi_eslesme] > 0.5:
        index = [sc["soru"] for sc in soru_cevap_listesi].index(en_iyi_eslesme)
        return soru_cevap_listesi[index]  # Bu satırı değiştirdim
    return None

@app.route('/', methods=['GET'])
def home():
    return "Hoşgeldiniz! Bu bir API servisidir. Lütfen dokümantasyonu inceleyiniz."

@app.route('/cevapla', methods=['POST'])
def cevapla():
    data = request.get_json()
    if not data or 'soru' not in data:
        return jsonify({'error': 'Soru alanı gereklidir'}), 400
    soru = data['soru']
    sonuc = benzer_soru_bul(soru, soru_cevap_listesi)
    if sonuc:
        return jsonify({'cevap': sonuc['cevap']})  # Bu satırı düzelttim
    else:
        return jsonify({'error': 'Uygun cevap bulunamadı'}), 404

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=5000, debug=True)
