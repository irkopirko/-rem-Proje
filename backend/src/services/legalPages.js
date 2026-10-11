const SUPPORT = 'inkakademidestek@outlook.com';
const SITE = 'https://inkakademionline.com';

function layout(title, body) {
  return `<!doctype html>
<html lang="tr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${title} · Ink Akademi</title>
<style>
  body { margin: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif; background: #111014; color: #f4eef2; line-height: 1.55; }
  main { max-width: 720px; margin: 0 auto; padding: 32px 22px 64px; }
  h1 { font-size: 28px; margin: 0 0 8px; }
  h2 { font-size: 18px; margin: 28px 0 8px; }
  p, li { color: #d7ced3; font-size: 15px; }
  .meta { color: #9a8f96; font-size: 13px; margin-bottom: 28px; }
  a { color: #e36a8c; }
  ul { padding-left: 20px; }
</style>
</head>
<body>
<main>
  <h1>${title}</h1>
  <p class="meta">Ink Akademi · Son güncelleme: 11 Ekim 2026</p>
  ${body}
  <p class="meta">İletişim: <a href="mailto:${SUPPORT}">${SUPPORT}</a> · <a href="${SITE}">${SITE.replace('https://', '')}</a></p>
</main>
</body>
</html>`;
}

export function privacyHtml() {
  return layout(
    'Gizlilik Politikası',
    `
  <p>Bu metin, Ink Akademi mobil uygulaması ve bağlı eğitim hizmetinde kişisel verilerin nasıl işlendiğini açıklar. Veri sorumlusu Ink Akademi’dir.</p>
  <h2>Hangi veriler işlenir</h2>
  <ul>
    <li>Hesap: ad, soyad, kullanıcı adı, e-posta, doğum tarihi, şifre özeti</li>
    <li>Profil fotoğrafı (isteğe bağlı)</li>
    <li>Eğitim: video izleme ilerlemesi, XP, seviye, rozetler, ödev dosyaları ve notlar</li>
    <li>Topluluk sohbeti mesajları</li>
    <li>Destek talepleri ve oturum belirteçleri</li>
  </ul>
  <h2>Amaç</h2>
  <p>Veriler hesabını açmak, eğitimi sunmak, ödevleri değerlendirmek, sohbeti işletmek, güvenliği sağlamak ve taleplerine cevap vermek için işlenir. Reklam ağıyla profilleme yapılmaz, veriler satılmaz.</p>
  <h2>Hizmet sağlayıcılar</h2>
  <p>Altyapı Railway üzerinde barındırılır. Ders videoları ve büyük dosyalar Bunny.net üzerinden iletilir. E-posta (doğrulama, şifre sıfırlama) Brevo ile gönderilir. Bu sağlayıcılar yalnızca hizmeti yürütmek için veri alır.</p>
  <h2>Saklama ve silme</h2>
  <p>Veriler hesabın açık olduğu sürece saklanır. Uygulamada <strong>Hesabımı Sil</strong> ile talebini ilettiğinde hesap, ilerleme, ödev, sohbet ve fotoğraf kayıtların silinir veya kimlikten arındırılır. Yasal saklama yükümlülüğü olan kayıtlar bu süreyle sınırlı tutulur.</p>
  <h2>Hakların</h2>
  <p>KVKK kapsamındaki erişim, düzeltme, silme ve itiraz hakların için ${SUPPORT} adresine yazabilirsin. Hesap ve şifre işlemlerini uygulamadan da yönetebilirsin.</p>
  <h2>Çocuklar</h2>
  <p>Hizmet mesleki eğitim içindir. Kayıtta doğum tarihi alınır. 18 yaşından küçük kullanıcılar yasal temsilci onayıyla hareket etmelidir.</p>
  <p><a href="/kosullar">Kullanım koşulları</a></p>
`
  );
}

export function termsHtml() {
  return layout(
    'Kullanım Koşulları',
    `
  <p>Ink Akademi uygulamasını kullanarak bu koşulları kabul etmiş olursun. Hizmet, dövme eğitimi içerikleri, ödevler, sohbet ve (üyeliğine göre) rehber kitabına erişim sağlar.</p>
  <h2>Hesap</h2>
  <p>Kayıt doğru bilgiyle yapılır. Şifreni başkasıyla paylaşma. Uygulama içinden hesabını silebilirsin; silme geri alınamaz.</p>
  <h2>Üyelik ve içerik</h2>
  <p>Yeni kayıtlar deneme sürümüyle başlar. Denemede yalnızca Ink Akademi Crew’un açtığı videolar görünür; ödevler ve rehber kitap satın alınmış üyeliklere (Light, Plus, Life Plus) aittir. Üyelik Ink Akademi tarafından, App Store dışı satış veya akademi kaydıyla tanımlanır. Uygulama, daha önce tanımlanmış üyeliğini okur; App Store üzerinden dijital üyelik satmaz.</p>
  <h2>Kullanıcı içeriği</h2>
  <p>Ödev dosyaları ve sohbet mesajları senin sorumluluğundadır. Hak ihlali, nefret, spam veya başkasının ödevini kopyalama yasaktır. Crew bildirilen içerikleri inceleyebilir, silebilir ve sohbet yasağı uygulayabilir.</p>
  <h2>Mağaza ürünleri</h2>
  <p>Uygulamadaki ürün kartları fiziksel mal satışına yönlendirir. Ödeme ilgili mağaza (ör. Shopier) üzerinde tamamlanır; bu satışlar Apple’ın uygulama içi satın alması değildir.</p>
  <h2>Sorumluluk</h2>
  <p>İçerikler eğitim amaçlıdır; tıbbi veya hukuki tavsiye değildir. Hizmet “olduğu gibi” sunulur. Kesinti, cihaz veya ağ kaynaklı kayıplardan Ink Akademi sorumlu tutulamaz.</p>
  <h2>İletişim</h2>
  <p>Soruların için ${SUPPORT}</p>
  <p><a href="/gizlilik">Gizlilik politikası</a></p>
`
  );
}
