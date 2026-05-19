OpenClaw, şu özellikleri sunan kendi kendine barındırılan bir AI ağ geçidi ve aracı çalışma zamanıdır:

- **Çok kanallı mesajlaşma**: Telegram botları, Discord entegrasyonları, Slack, e-posta ve diğer mesajlaşma platformlarını birleşik bir ağ geçidi üzerinden bağlayın
- **Aracı iş akışları**: Araç kullanabilen, muhakeme yapabilen ve görevleri özerk olarak yürütebilen AI aracıları dağıtın
- **WebSocket/HTTP ağ geçidi**: Tam çift yönlü akış desteğiyle harici entegrasyonlar için esnek bir API sunun
- **YunoHost entegrasyonu**: YunoHost kimlik doğrulamanız üzerinden SSO geçişi ile izole sistem kullanıcısı olarak çalışır

Ağ geçidi yerel olarak `127.0.0.1:18789` üzerinde çalışır ve yalnızca NGINX üzerinden erişilir; NGINX TLS sonlandırması ve SSO header enjeksiyonunu gerçekleştirerek sorunsuz YunoHost kullanıcı kimlik doğrulaması sağlar.

## Temel Özellikler

| Özellik | Açıklama |
|---------|----------|
| Çok kanallı | Telegram, Discord, Slack, E-posta ve daha fazlası |
| Aracı AI | Araç kullanımı ve muhakeme ile özerk aracılar |
| WebSocket akışı | Çift yönlü gerçek zamanlı iletişim |
| SSO entegrasyonu | Otomatik YunoHost kullanıcı kimlik doğrulaması |
| Kendi kendine barındırılan | Verileriniz ve altyapınız üzerinde tam kontrol |
| Çoklu örnek | Bir sunucuda birden fazla bağımsız örnek çalıştırın |