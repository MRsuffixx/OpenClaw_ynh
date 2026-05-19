# OpenClaw Kurulumundan Sonra

## Kurulum Tamamlandı

OpenClaw örneğiniz artık kurulu ve çalışıyor.

## Erişim Bilgileri

- **Ağ Geçidi URL'si**: `https://__DOMAIN____PATH__`
- **Ağ Geçidi Bağlantı Noktası**: `__PORT__` (yalnızca 127.0.0.1'e bağlı)
- **Kurulum Dizini**: `__INSTALL_DIR__`
- **Veri Dizini**: `__DATA_DIR__`
- **Uygulama Kimliği**: `__APP__`

## Sonraki Adımlar

1. **Ağ geçidine erişin**: Tarayıcınızda `https://__DOMAIN____PATH__` adresini açın
2. **Kanalları yapılandırın**: `sudo -u __APP__ openclaw channel add <kanal>` ile mesajlaşma kanalları ekleyin
3. **Kimlik doğrulamayı ayarlayın**: Ağ geçidi YunoHost SSO kullanır; YunoHost kimlik bilgilerinizle giriş yapın
4. **Güncelleme kanalını yapılandırın**: Stable/beta kanalı seçmek için YunoHost yapılandırma panelini kullanın

## Varsayılan Kimlik Bilgileri

Varsayılan kimlik bilgisi gerekmez — kimlik doğrulama tamamen YunoHost SSO üzerinden yapılır.

## Sağlık Kontrolü

Ağ geçidinin çalışıp çalışmadığını doğrulayın:

```bash
curl http://127.0.0.1:__PORT__/readyz
```

## Günlükler

Günlükleri `/var/log/__APP__/` adresinde görüntüleyin:
- `__APP__.log` — Ağ geçidi stdout
- `error.log` — Ağ geçidi stderr
- `install.log` — Kurulum günlüğü