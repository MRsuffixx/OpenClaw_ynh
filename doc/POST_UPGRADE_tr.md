# OpenClaw Güncellemeden Sonra

## Güncelleme Tamamlandı

OpenClaw örneğiniz başarıyla güncellendi.

## Güncelleme Sonrası Kontrol Listesi

1. **Ağ geçidinin çalıştığını doğrulayın**: `curl http://127.0.0.1:__PORT__/readyz`
2. **Sürümü kontrol edin**: `sudo -u __APP__ openclaw --version`
3. **Doctor'ı çalıştırın**: `sudo -u __APP__ openclaw doctor`
4. **Günlükleri doğrulayın**: Herhangi bir sorun için `/var/log/__APP__/upgrade.log` dosyasını kontrol edin

## Sorunlar Oluşursa

Güncellemeden sonra ağ geçidi başlamıyorsa:

1. Hata günlüğünü kontrol edin: `tail -50 /var/log/__APP__/error.log`
2. Yapılandırmayı yedekten geri yükleyin: Yapılandırma dosyaları `openclaw.json.pre-upgrade.*` olarak yedeklenir
3. Hizmeti yeniden başlatın: `yunohost service restart __APP__`
4. Doctor'ı çalıştırın: `sudo -u __APP__ openclaw doctor --fix`

## Geri Alma

Güncelleme tamamen başarısız olursa, güncelleme öncesinde oluşturulan yedekten geri yükleyin:

```bash
yunohost backup restore <yedek_adı> --apps __APP__
```

## Günlükler

Güncelleme günlüklerini `/var/log/__APP__/upgrade.log` adresinde görüntüleyin