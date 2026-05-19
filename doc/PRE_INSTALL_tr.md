# OpenClaw Kurulumundan Önce

## Ön Koşullar

OpenClaw'u kurmadan önce, YunoHost sunucunuzun aşağıdaki gereksinimleri karşıladığından emin olun:

- **YunoHost sürümü**: 11.2 veya üstü
- **Mimari**: `amd64` veya `arm64` (Raspberry Pi 4/5 desteklenir; 32-bit ARM desteklenmez)
- **Disk alanı**: Node.js, OpenClaw paketi ve çalışma alanı için en az 1 GB
- **RAM**: Derleme için 512 MB, çalışma zamanı için 256 MB

## Önemli Notlar

- OpenClaw yalnızca `127.0.0.1:18789` adresine bağlanır — doğrudan internete asla açılmaz
- Ağ geçidine NGINX ile TLS sonlandırması ve SSO geçişi üzerinden erişilir
- Kurulum, kendi Node.js ortamını sağlayan resmi `install-cli.sh` betiği aracılığıyla yapılır
- Veri dizini (`/home/openclaw/.openclaw/`) kaldırma sırasında korunur; tüm verileri silmek için `--purge` kullanın

## Kurulum Öncesi Kontrol Listesi

- [ ] YunoHost 11.2+ kurulu ve çalışıyor
- [ ] Domain YunoHost'ta yapılandırılmış
- [ ] DNS, domaininiz için düzgün ayarlanmış
- [ ] Başka bir uygulama 18789 bağlantı noktasını kullanmıyor (veya YunoHost'un otomatik atamasına izin verin)
- [ ] YunoHost'a admin erişiminiz var