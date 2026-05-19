# OpenClaw Güncellemeden Önce

## Güncelleme Öncesi Notları

OpenClaw'u güncellemeden önce, aşağıdaki notlara dikkat edin:

- **Yedekleme önerilir**: Güncellemeden önce `yunohost backup create --apps openclaw` komutunu çalıştırın
- **Hizmet kesintisi**: Ağ geçidi güncelleme sırasında durdurulacak
- **Veri dizini korunur**: Veri dizini (`/home/__APP__/.openclaw/`) otomatik güvenlik yedeklemelerine **dahil edilmez**
- **Yapılandırma değişiklikleri**: `openclaw.json` dosyasındaki kullanıcı değişikliği ayarları mümkünse korunur

## Güncelleme Süreci

1. Güncelleme betiği ağ geçidi hizmetini durdurur
2. `openclaw update` veya `install-cli.sh` aracılığıyla yeni OpenClaw sürümünü indirir ve çalıştırır
3. Tüm yapılandırma dosyalarını yeniden oluşturur
4. Sorunları gidermek için `openclaw doctor --fix` komutunu çalıştırır
5. Ağ geçidini yeniden başlatır ve sağlığını doğrular

## Korunan Bilgiler

- `~/.openclaw/credentials/` dizinindeki kanal kimlik bilgileri
- `~/.openclaw/agents/` dizinindeki aracı durumu
- `~/.openclaw/workspace/` dizinindeki çalışma alanı verileri
- Kullanıcı değişikliği `openclaw.json` ayarları (üzerine yazmadan önce yedeklenir)

## Değişebilecek Bilgiler

- Dahili OpenClaw dosya yapısı
- `openclaw.json` dosyasındaki varsayılan değerler
- Systemd hizmet birimi parametreleri