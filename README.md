# Nöbetçi Eczane

Türkiye'deki nöbetçi eczaneleri harita üzerinde gösteren, yapay zeka destekli sesli arama ile ilaç stok sorgulama yapabilen Flutter mobil uygulaması.

---

## Özellikler

- **Harita**: OpenStreetMap üzerinde tüm eczaneler gösterilir. Nosyapi entegrasyonu ile nöbetçi eczaneler ayrı renkle işaretlenir.
- **Konum işaretleme**: Haritada uzun basarak özel konum seçilebilir, o konuma yakın eczaneler yüklenir.
- **Sesli ilaç sorgulama**: Seçilen eczane otomatik olarak aranır, yapay zeka ilaç sorusunu sorar, eczacının cevabını kaydeder, Whisper ile metne çevirir ve GPT ile analiz eder.
- **Çoklu ilaç sorgusu**: Tek aramada birden fazla ilaç ve dozaj bilgisi sorulabilir.
- **Görsel ilaç tanıma**: İlaç kutusu fotoğrafı, reçete veya el yazısı reçete fotoğrafından ilaç ismi ve mg bilgisi otomatik çıkarılır (GPT-4o Vision).
- **Gerçek zamanlı güncelleme**: Sorgu sonucu Firebase Realtime Database üzerinden anlık olarak uygulamaya yansır.
- **Kullanıcı / Eczane hesapları**: Ayrı kayıt tipleri; eczaneler telefon numarasıyla kayıt olursa sistem öncelikli olarak o numarayı arar.

---

## Sistem Mimarisi

```
Flutter App
    │
    ├── Harita (OpenStreetMap + Overpass API + Nosyapi)
    │
    └── İlaç Sorgusu
            │
            ▼
    Railway Backend (Node.js/Express)
            │
            ├── Twilio → Eczaneyi arar
            │       └── Eczane açar → TwiML: Türkçe mesaj oynatır + ses kaydeder
            │
            ├── OpenAI Whisper → Ses kaydını metne çevirir
            │
            ├── GPT-4o-mini → Cevabı analiz eder (mevcut/yok/alternatif/dozaj)
            │
            └── Firebase Realtime DB → Sonucu yazar
                        │
                        ▼
                Flutter App (realtime listener) → UI güncellenir
```

### Sesli Arama Akışı

1. Kullanıcı eczane seçer, ilaç listesi oluşturur
2. Flutter → `POST /make-call` → Railway backend
3. Backend → Twilio API → Eczane telefonu çalar
4. Eczane açar → Twilio → `GET /twiml` → Backend TwiML döner:
   > *"Merhaba, Nöbetçi Eczane uygulaması adına arıyoruz. Parol 500mg ve Augmentin 625mg mevcut mu? Lütfen her biri için ayrı ayrı yanıtlayın."*
5. Eczacı konuşur (max 30 sn) → Twilio kaydeder
6. Twilio → `POST /recording` → Backend
7. Backend → **OpenAI Whisper** → Türkçe transkript
8. Backend → **GPT-4o-mini** → Yapılandırılmış analiz:
   ```json
   {
     "available": true,
     "message": "Parol var, Augmentin yok",
     "fullMessage": "Parol 500mg stokta mevcut. Augmentin 625mg şu an yok, 1000mg formu var.",
     "alternative": "Augmentin 1000mg"
   }
   ```
9. Backend → **Firebase** → `queries/{id}` güncellenir
10. Flutter realtime listener → Ekran anında güncellenir

---

## Kullanılan Teknolojiler

### Mobil (Flutter)
| Paket | Kullanım |
|-------|----------|
| `flutter_map` + `latlong2` | OpenStreetMap harita |
| `geolocator` | GPS konumu |
| `provider` | State management |
| `firebase_core` + `firebase_auth` + `firebase_database` | Auth ve realtime DB |
| `image_picker` | Fotoğraf seçimi |
| `flutter_dotenv` | Ortam değişkenleri |
| `http` + `dio` | API istekleri |
| `shared_preferences` | Yerel sorgu geçmişi |
| `url_launcher` | WhatsApp fallback |

### Backend (Node.js/Express — Railway)
| Paket | Kullanım |
|-------|----------|
| `twilio` | Otomatik sesli arama |
| `openai` | Whisper transkripsiyon + GPT analiz |
| `firebase-admin` | Firebase'e yazma |
| `axios` | Twilio ses dosyası indirme |
| `express` | HTTP sunucusu |

### Harici Servisler
| Servis | Kullanım |
|--------|----------|
| **OpenStreetMap + Overpass API** | Eczane konumları (ücretsiz) |
| **Nosyapi** | Nöbetçi eczane verisi |
| **Twilio Voice** | Otomatik telefon araması (~$0.02/dk) |
| **OpenAI Whisper** | Ses → metin (~$0.006/dk) |
| **GPT-4o-mini** | Yanıt analizi (~$0.001/sorgu) |
| **Firebase** | Auth + Realtime Database |
| **Railway** | Backend hosting |

---


## Maliyet (Tahmini)

| İşlem | Maliyet |
|-------|---------|
| Her sesli sorgu (30 sn) | ~$0.03 |
| Görsel ilaç tanıma | ~$0.01 |
| Firebase (10k kullanıcı) | Ücretsiz tier |
| Railway backend | Ücretsiz tier (500h/ay) |

---

## Veri Yapısı (Firebase)

```
├── users/{uid}
│   ├── name, email, role: "user"
│
├── pharmacies/{uid}
│   ├── name, email, phone, role: "pharmacy"
│
└── queries/{id}
    ├── drugName, drugList[], pharmacyName
    ├── status: pending|calling|transcribing|available|unavailable|no-answer|unclear
    ├── callMessage (kısa özet)
    ├── fullMessage (detaylı GPT yanıtı)
    ├── alternative, transcript, timestamp
```

---

## Ekran Görüntüleri

<img width="344" height="707" alt="Ekran Resmi 2026-06-30 10 05 48" src="https://github.com/user-attachments/assets/6c713f16-32b3-40b8-a052-38da35f70e43" />

<img width="345" height="710" alt="Ekran Resmi 2026-06-30 10 08 30" src="https://github.com/user-attachments/assets/a58dc3eb-ddc7-42ab-82bb-6e3f2951896b" />

<img width="342" height="709" alt="Ekran Resmi 2026-06-30 10 06 19" src="https://github.com/user-attachments/assets/42992e47-2a78-48ad-956e-0decc19ff241" />

<img width="345" height="710" alt="IMG_3846" src="https://github.com/user-attachments/assets/59bd5d74-b183-4a27-ba0f-cb910fb7077b" />

<img width="346" height="708" alt="Ekran Resmi 2026-06-30 10 06 49" src="https://github.com/user-attachments/assets/03007b9f-3d77-48d1-91c4-d4e34c02bf33" />



## Lisans

MIT
