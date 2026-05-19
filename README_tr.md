# YunoHost için OpenClaw

[![Entegrasyon seviyesi](https://dash.yunohost.org/integration/openclaw.svg)](https://dash.yunohost.org/appci/app/openclaw) ![Bakım durumu](https://ci-apps.yunohost.org/ci/badges/openclaw.maintain.svg)

*[Bu readme dosyasını Fransızca okuyun.](./README_fr.md)*

> OpenClaw, çok kanallı mesajlaşma platformlarını tek bir geçit üzerinden birleştiren ve otonom AI ajanları desteği sunan, kendi kendine barındırılan bir AI geçidi ve ajan çalışma zamanı ortamıdır.

## Genel Bakış

OpenClaw, kendi sunucunuzda çalışan bir AI geçidi ve ajan çalışma zamanı ortamıdır. `127.0.0.1:18789` adresinde bir WebSocket/HTTP geçidi sunar ve yalnızca NGINX üzerinden TLS sonlandırması ve YunoHost SSO geçişi ile erişilecek şekilde tasarlanmıştır.

### Temel Özellikler

- **Çok kanallı mesajlaşma**: Telegram botları, Discord entegrasyonları, Slack, e-posta ve diğer mesajlaşma platformlarını bağlayın
- **Ajan tabanlı iş akışları**: Akıl yürütebilen, araç kullanabilen ve görevleri otonom olarak yerine getirebilen AI ajanları dağıtın
- **WebSocket/HTTP geçidi**: Harici entegrasyonlar için çift yönlü akış desteği sunan esnek API
- **YunoHost entegrasyonu**: YunoHost kullanıcı kimlik bilgilerinizle otomatik SSO kimlik doğrulaması
- **Kendi kendine barındırma**: Verileriniz ve altyapınız üzerinde tam kontrol
- **Çoklu örnek**: Tek bir YunoHost sunucusunda birden fazla bağımsız örnek çalıştırma

## Sınırlamalar

- Bu paket tarafından `dev` güncelleme kanalı desteklenmemektedir
- 32-bit ARM (`armhf`) desteklenmemektedir — yalnızca `amd64` ve `arm64`
- Geçit yalnızca `127.0.0.1` adresine bağlanır ve asla doğrudan internete açık hale getirilmez

## Gereksinimler

- YunoHost 11.2 veya üzeri
- Mimari: `amd64` veya `arm64`
- En az 1 GB boş disk alanı
- Kurulum için 512 MB RAM, çalışma zamanı için 256 MB RAM

## Kurulum

### YunoHost yönetim panelinden

1. YunoHost yönetim arayüzüne giriş yapın
2. **Uygulamalar** → **Yükle** menüsüne gidin
3. "OpenClaw" araması yapın ve **Yükle**'ye tıklayın
4. Kurulum parametrelerini doldurun:
   - **Alan adı**: Bir alan adı veya alt alan adı seçin
   - **Yol**: Genellikle `/`
   - **Güncelleme kanalı**: `stable` (önerilen) veya `beta`
   - **OpenClaw sürümü**: Otomatik en son kararlı sürüm için `latest` veya belirli bir sürüm girin
   - **Geçit kimlik doğrulama token'ı**: Otomatik oluşturulması için boş bırakın veya kendi token'ınızı girin (en az 16 karakter)
   - **Otomatik güncellemeleri etkinleştir**: `no` (önerilen) veya `yes`
5. **Yükle**'ye tıklayın

### Komut satırından

```bash
sudo yunohost app install https://github.com/MRsuffixx/OpenClaw_ynh
```

### Geliştirme sürümünü test etme

```bash
sudo yunohost app install https://github.com/MRsuffixx/OpenClaw_ynh/tree/testing --debug
```

## Yapılandırma

Kurulumdan sonra, aşağıdaki ayarları yönetmek için **Uygulamalar** → **OpenClaw** → **Yapılandırma paneli** üzerinden erişim sağlayın:

- **Güncelleme kanalı**: `stable` ve `beta` arasında geçiş yapın
- **Otomatik güncelleme**: Otomatik güncellemeleri etkinleştirin veya devre dışı bırakın
- **Geçit kimlik doğrulama token'ı**: API erişimi için paylaşılan gizli anahtarı güncelleyin

## Kullanım

### Geçide erişim

Tarayıcınızda `https://alan-adiniz.com/` adresini açın. Kimlik doğrulaması, YunoHost SSO üzerinden otomatik olarak yapılır — YunoHost kimlik bilgilerinizle giriş yapın.

### CLI komutları

OpenClaw komutlarını uygulama kullanıcısı olarak çalıştırın:

```bash
sudo -u openclaw openclaw <komut>
```

Çoklu örnek kurulumlarında, örnek adını kullanın (ör. `openclaw__2`):

```bash
sudo -u openclaw__2 openclaw <komut>
```

### Yaygın komutlar

| Komut | Açıklama |
|-------|----------|
| `openclaw gateway start` | Geçidi başlat |
| `openclaw gateway stop` | Geçidi durdur |
| `openclaw gateway restart` | Geçidi yeniden başlat |
| `openclaw channel add <ad>` | Bir mesajlaşma kanalı ekle |
| `openclaw doctor` | Sağlık tanılama çalıştır |
| `openclaw --version` | Yüklü sürümü göster |

### Sağlık kontrolü

```bash
curl http://127.0.0.1:18789/readyz
```

### Günlük kayıtları (Loglar)

| Günlük | Yol |
|--------|-----|
| Geçit stdout | `/var/log/openclaw/openclaw.log` |
| Geçit stderr | `/var/log/openclaw/error.log` |
| Kurulum günlüğü | `/var/log/openclaw/install.log` |
| Yükseltme günlüğü | `/var/log/openclaw/upgrade.log` |

## Yükseltme

### Yönetim panelinden

**Uygulamalar** → **OpenClaw** → **Güncelle** menüsüne gidin

### Komut satırından

```bash
sudo yunohost app upgrade openclaw
```

Test sürümüne yükseltmek için:

```bash
sudo yunohost app upgrade openclaw -u https://github.com/MRsuffixx/OpenClaw_ynh/tree/testing --debug
```

## Yedekleme ve Geri Yükleme

### Yedek oluşturma

```bash
sudo yunohost backup create --apps openclaw
```

Bu komut, tüm kimlik bilgileri ve ajan durumunu içeren tam veri dizinini yedekler.

### Yedekten geri yükleme

```bash
sudo yunohost backup restore <yedek_adi> --apps openclaw
```

### Veri koruma

- Veri dizini (`/home/openclaw/.openclaw/`), uygulama kaldırıldıktan sonra **korunur**
- Tüm verileri kalıcı olarak silmek için `yunohost app remove openclaw --purge` komutunda `--purge` parametresini kullanın
- Yükseltme öncesi otomatik güvenlik yedeklemesi, veri dizinini **içermez** (büyük olabileceği için)

## Kaldırma

```bash
sudo yunohost app remove openclaw
```

Bu komut uygulamayı kaldırır ancak verilerinizi korur. Tüm verileri kaldırmak için:

```bash
sudo yunohost app remove openclaw --purge
```

## Mimari

```
Tarayıcı / YunoHost SSO
        │
        ▼
   NGINX (TLS sonlandırması, SSO başlık enjeksiyonu)
        │  X-Remote-User: <ldap_uid>
        │  X-Remote-Email: <email>
        │  Upgrade: websocket
        ▼
   OpenClaw Geçidi (127.0.0.1:18789)
        │
        ├── ~/.openclaw/openclaw.json     (çalışma zamanı yapılandırması)
        ├── ~/.openclaw/credentials/      (kanal token'ları)
        ├── ~/.openclaw/agents/           (ajan durumu)
        └── ~/.openclaw/workspace/        (beceriler, hafızalar)
```

## Dokümantasyon ve kaynaklar

- **Resmi dokümantasyon**: https://docs.openclaw.ai
- **Resmi web sitesi**: https://openclaw.ai
- **Resmi kod deposu**: https://github.com/openclaw/openclaw
- **YunoHost paketleme dokümantasyonu**: https://doc.yunohost.org/dev/packaging/
- **Hata bildir**: https://github.com/MRsuffixx/OpenClaw_ynh/issues

## Katkıda Bulunma

Lütfen pull request'lerinizi `testing` dalına gönderin.

Testing dalını denemek için:

```bash
sudo yunohost app install https://github.com/MRsuffixx/OpenClaw_ynh/tree/testing --debug
sudo yunohost app upgrade openclaw -u https://github.com/MRsuffixx/OpenClaw_ynh/tree/testing --debug
```

## Paketlenen Sürüm

**OpenClaw sürümü**: 1.0~ynh1

---

*Uygulama paketleme hakkında daha fazla bilgi:* https://doc.yunohost.org/dev/packaging/