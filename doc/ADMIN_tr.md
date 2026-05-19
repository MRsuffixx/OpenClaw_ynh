# OpenClaw Yönetim Kılavuzu

## CLI'ye Erişim

OpenClaw komutlarını uygulama kullanıcısı olarak çalıştırın:

```bash
sudo -u openclaw openclaw <komut>
```

Çoklu örnek kurulumlarında `openclaw` yerine örnek adını kullanın (örn. `openclaw__2`).

## Sağlık Kontrolü

Ağ geçidinin çalışıp çalışmadığını doğrulayın:

```bash
curl http://127.0.0.1:18789/readyz
```

## Günlük Konumları

| Günlük | Yol |
|--------|-----|
| Ağ geçidi stdout | `/var/log/openclaw/openclaw.log` |
| Ağ geçidi stderr | `/var/log/openclaw/error.log` |
| Kurulum/güncelleme günlüğü | `/var/log/openclaw/install.log` |
| Geri yükleme günlüğü | `/var/log/openclaw/restore.log` |
| URL değişikliği günlüğü | `/var/log/openclaw/change_url.log` |

## Kanalları Yönetme

OpenClaw, birden fazla mesajlaşma kanalını (Telegram, Discord vb.) bağlamayı destekler. Kurulumdan sonra kanalları eklemek için CLI'yi kullanın:

```bash
sudo -u openclaw openclaw channel add telegram
```

Kanal kimlik bilgileri `/home/openclaw/.openclaw/credentials/` dizininde saklanır ve güncellemeler ile yedeklemeler arasında korunur.

## OpenClaw'u Güncelleme

Güncellemeler YunoHost paketi升级 mekanizması üzerinden işlenir:

```bash
yunohost app upgrade openclaw
```

Güncelleme kanalını (stable/beta) değiştirmek için yapılandırma panelini kullanın. Bu paket `dev` kanalını desteklemez.

## Yedekleme Davranışı

- `$data_dir` (`/home/openclaw/.openclaw/`) tüm kimlik bilgilerini, ajanları ve çalışma alanı verilerini içerir
- Uygulama kaldırıldıktan sonra **korunur** — yalnızca `--purge` ile kalıcı olarak silinir
- Safety-backup-before-upgrade sırasında veri dizini **dahil edilmez** (büyük olabilir)
- `yunohost backup create --apps openclaw` ile manuel yedeklemeler veri dizinini **içerir**

## Hizmet Yönetimi

Ağ geçidini başlatın, durdurun veya yeniden başlatın:

```bash
yunohost service start openclaw
yunohost service stop openclaw
yunohost service restart openclaw
```

Hizmet durumunu kontrol edin:

```bash
yunohost service status openclaw
```

## Sorun Giderme

Ağ geçidi başlamıyorsa:

1. Günlükleri kontrol edin: `tail -f /var/log/openclaw/error.log`
2. Doctor'ı çalıştırın: `sudo -u openclaw openclaw doctor`
3. Hizmeti yeniden başlatın: `yunohost service restart openclaw`

İzin sorunları için:

```bash
chown -R openclaw:openclaw /home/openclaw/.openclaw/
```

## Mimari

Ağ geçidi yalnızca `127.0.0.1:18789` adresine bağlanır ve doğrudan internete açılmaz. Tüm harici trafik NGINX üzerinden yönlendirilir; NGINX TLS sonlandırması ve SSO header enjeksiyonunu gerçekleştirir.

```
Tarayıcı → NGINX (TLS) → OpenClaw Ağ Geçidi (127.0.0.1:18789)
```

## Çoklu Örnek

Her örnek ayrı bir sistem kullanıcısı olarak çalışır (`openclaw`, `openclaw__2` vb.) kendi bağlantı noktası, veri dizini ve systemd hizmetiyle. İkinci örnek komutları için `sudo -u openclaw__2` kullanın.