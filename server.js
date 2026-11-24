const express = require('express');
const sql = require('mssql');
const cors = require('cors');
const path = require('path');
const fs = require('fs'); // Dosya kontrolü için

const app = express();
app.use(cors());
app.use(express.json());

// 1. STATİK DOSYALARI AÇ (HTML/CSS/JS/Resimler için)
// Eskisi: app.use(express.static(__dirname));
app.use(express.static(path.join(__dirname, 'public')));

// 2. VERİTABANI BAĞLANTISI (Buraya KENDİ şifreni yaz!)
const dbConfig = {
    user: 'sa',
    password: 'BiletBul2026', 
    server: 'localhost',
    database: 'Otobus-Bilet',
    port: 1433,
    options: {
        encrypt: false,
        trustServerCertificate: true
    }
};

// 3. ANA SAYFAYI GÖSTERME (Hata kontrolü eklendi)
app.get('/', (req, res) => {
   // Eskisi: const indexPath = path.join(__dirname, 'index.html');
const indexPath = path.join(__dirname, 'public', 'index.html');
    
    if (fs.existsSync(indexPath)) {
        res.sendFile(indexPath);
    } else {
        res.status(404).send(`
            <h2>Hata: index.html bulunamadı!</h2>
            <p>Node.js şu an bu klasöre bakıyor: <b>${__dirname}</b></p>
            <p>Lütfen ana sayfa dosyanın adının tam olarak <b>index.html</b> olduğundan emin ol.</p>
        `);
    }
});

// 4. SEFER ARAMA API (Maraş ve İnce Turizm için)
app.get('/api/seferler', async (req, res) => {
    try {
        const { kalkis, varis, tarih } = req.query;
        const pool = await sql.connect(dbConfig);
        const result = await pool.request()
            .input('p_kalkis', sql.VarChar(50), kalkis)
            .input('p_varis', sql.VarChar(50), varis)
            .input('p_tarih', sql.Date, tarih)
            .execute('UygunSeferleriListele');
        res.json(result.recordset);
    } catch (err) {
        console.error("SQL Hatası (Seferler):", err);
        res.status(500).json({ error: err.message });
    }
});

// 5. KOLTUK BİLGİSİ API (SQL'deki gerçek dolu koltuklar için)
app.get('/api/koltuklar/:seferId', async (req, res) => {
    try {
        const pool = await sql.connect(dbConfig);
        
        // Sefer detayları
        const seferRes = await pool.request()
            .input('seferId', sql.Int, req.params.seferId)
            .query(`SELECT S.*, O.total_koltuk_sayisi FROM Sefer S JOIN Otobus O ON S.sefer_otobus_id = O.otobus_id WHERE S.sefer_id = @seferId`);
        
      // Dolu koltuklar ve cinsiyetler (LEFT JOIN ile esnek hale getirdik)
        const doluRes = await pool.request()
            .input('seferId', sql.Int, req.params.seferId)
            .query(`
                SELECT K.koltuk_no, Y.cinsiyet 
                FROM Koltuk K
                LEFT JOIN Bilet B ON K.bilet_id = B.bilet_id
                LEFT JOIN Satin_Alir SA ON B.bilet_id = SA.bilet_id
                LEFT JOIN Yolcu Y ON SA.tc_no = Y.tc_no
                WHERE K.sefer_id = @seferId AND K.bilet_id IS NOT NULL
            `);

        res.json({
            sefer: seferRes.recordset[0],
            doluKoltuklar: doluRes.recordset
        });
    } catch (err) {
        console.error("SQL Hatası (Koltuklar):", err);
        res.status(500).json({ error: err.message });
    }
});

// BİLET SATIN ALMA (ÖDEME) API'Sİ
app.post('/api/satin-al', async (req, res) => {
    try {
        // req.body içinden 'sifre' değişkenini de alıyoruz
        const { tcNo, ad, soyad, sifre, kartNo, skt, cvc, seferId, koltuklar } = req.body; 
        const pool = await sql.connect(dbConfig);

        // --- YENİ EKLENEN: GERÇEK ÜYE ŞİFRESİ KONTROLÜ ---
        // SQL'den kullanıcının gerçek şifresini çekip kontrol ediyoruz
        const yolcuCheck = await pool.request()
            .input('tc_no', sql.Char(11), tcNo)
            .query('SELECT sifre FROM Yolcu WHERE tc_no = @tc_no');

        // Eğer TC yoksa:
        if (yolcuCheck.recordset.length === 0) {
            return res.status(400).json({ success: false, error: 'Sisteme kayıtlı böyle bir TC Kimlik Numarası bulunamadı!' });
        }

        // Eğer TC var ama girilen şifre veritabanındaki ile uyuşmuyorsa:
        if (yolcuCheck.recordset[0].sifre !== sifre) {
            return res.status(400).json({ success: false, error: 'Girdiğiniz üyelik şifresi hatalı! Lütfen tekrar deneyin.' });
        }
        // --------------------------------------------------

        // Şifre doğruysa, seçilen her koltuk için SQL'deki kayıt motorunu (Procedure) çalıştır
        for (let koltuk of koltuklar) {
            let cinsiyet = koltuk.gender === 'female' ? 'K' : 'E';
            let biletFiyati = 300; 

            await pool.request()
                .input('p_tc_no', sql.Char(11), tcNo)
                .input('p_ad', sql.VarChar(50), ad)
                .input('p_soy_ad', sql.VarChar(50), soyad)
                .input('p_cinsiyet', sql.Char(1), cinsiyet)
                .input('p_kart_no', sql.VarChar(16), kartNo)
                .input('p_skt', sql.VarChar(5), skt)
                .input('p_cvc', sql.Char(3), cvc)
                .input('p_sefer_id', sql.Int, parseInt(seferId))
                .input('p_koltuk_no', sql.Int, koltuk.num)
                .input('p_fiyat', sql.Decimal(10,2), biletFiyati)
                .execute('SP_BiletSatinAl');
        }

        // --- YENİ EKLENEN KISIM: Kesilen Biletlerin PNR (bilet_id) numaralarını bul ---
        const pnrResult = await pool.request()
            .input('tc', sql.Char(11), tcNo)
            .input('sefer', sql.Int, parseInt(seferId))
            .query(`
                SELECT TOP ${koltuklar.length} B.bilet_id 
                FROM Bilet B
                JOIN Satin_Alir SA ON B.bilet_id = SA.bilet_id
                WHERE SA.tc_no = @tc AND B.sefer_id = @sefer
                ORDER BY B.bilet_id DESC
            `);
        
        // PNR numaralarını bir diziye (array) çevirip sıralamasını düzeltiyoruz
        const pnrListesi = pnrResult.recordset.map(r => r.bilet_id).reverse();

        // Yanıt kısmında pnrs bilgisini de frontend'e yolluyoruz:
        res.json({ success: true, message: "Biletler başarıyla oluşturuldu!", pnrs: pnrListesi });

        res.json({ success: true, message: "Biletler başarıyla oluşturuldu!" });
    } catch (err) {
        console.error("Satın Alma Hatası:", err);
        res.status(500).json({ success: false, error: err.message });
    }
});

// ÜYE GİRİŞİ API'Sİ
app.post('/api/login', async (req, res) => {
    try {
        const { email, password } = req.body;
        const pool = await sql.connect(dbConfig);

        // Yolcu tablosunda bu email ve şifreye sahip biri var mı kontrol ediyoruz
        const result = await pool.request()
            .input('email', sql.VarChar(100), email)
            .input('sifre', sql.VarChar(100), password)
            .query(`
                SELECT tc_no, ad, soy_ad 
                FROM Yolcu 
                WHERE e_mail = @email AND sifre = @sifre
            `);

        if (result.recordset.length > 0) {
            // Eşleşme bulundu, kullanıcı sisteme kayıtlı!
            const user = result.recordset[0];
            res.json({ success: true, message: "Giriş başarılı", user: user });
        } else {
            // Eşleşme yok (Yanlış şifre veya email)
            res.json({ success: false, message: "Hatalı e-posta veya şifre girdiniz!" });
        }
    } catch (err) {
        console.error("Giriş Hatası:", err);
        res.status(500).json({ success: false, error: err.message });
    }
});

// ÜYE KAYIT API'Sİ
app.post('/api/register', async (req, res) => {
    try {
        const { tcNo, ad, soyad, cinsiyet, telefon, email, sifre } = req.body;
        const pool = await sql.connect(dbConfig);

        // 1. Önce kontrol edelim: Bu TC veya E-Posta zaten kayıtlı mı?
        const checkResult = await pool.request()
            .input('tc', sql.Char(11), tcNo)
            .input('email', sql.VarChar(100), email)
            .query(`SELECT tc_no FROM Yolcu WHERE tc_no = @tc OR e_mail = @email`);

        if (checkResult.recordset.length > 0) {
            return res.json({ success: false, message: "Bu TC Kimlik Numarası veya E-Posta adresi zaten sistemde kayıtlı!" });
        }

        // 2. Kayıtlı değilse, veritabanına aslanlar gibi ekle
        await pool.request()
            .input('tc', sql.Char(11), tcNo)
            .input('ad', sql.VarChar(50), ad)
            .input('soyad', sql.VarChar(50), soyad)
            .input('cinsiyet', sql.Char(1), cinsiyet)
            .input('telefon', sql.VarChar(15), telefon)
            .input('email', sql.VarChar(100), email)
            .input('sifre', sql.VarChar(100), sifre)
            .query(`
                INSERT INTO Yolcu (tc_no, ad, soy_ad, cinsiyet, telefon, e_mail, sifre)
                VALUES (@tc, @ad, @soyad, @cinsiyet, @telefon, @email, @sifre)
            `);

        res.json({ success: true, message: "Kayıt başarıyla oluşturuldu." });
    } catch (err) {
        console.error("Kayıt Hatası:", err);
        res.status(500).json({ success: false, error: err.message });
    }
});

// BİLET (PNR) SORGULAMA API'Sİ
app.post('/api/sorgula', async (req, res) => {
    try {
        const { pnr, iletisim } = req.body;
        const pool = await sql.connect(dbConfig);

        // Bilet_id (PNR) ve Yolcu iletişim bilgisi eşleşiyor mu diye dev bir sorgu atıyoruz
        const result = await pool.request()
            .input('pnr', sql.Int, parseInt(pnr))
            .input('iletisim', sql.VarChar(100), iletisim)
            .query(`
                SELECT 
                    B.bilet_id,
                    Y.ad + ' ' + Y.soy_ad AS yolcu,
                    F.firma_adi,
                    S.kalkis_sehri + ' ➔ ' + S.varis_sehri AS guzergah,
                    S.sefer_tarihi,
                    S.kalkis_saati,
                    K.koltuk_no,
                    O.odeme_durumu
                FROM Bilet B
                INNER JOIN Satin_Alir SA ON B.bilet_id = SA.bilet_id
                INNER JOIN Yolcu Y ON SA.tc_no = Y.tc_no
                INNER JOIN Sefer S ON B.sefer_id = S.sefer_id
                INNER JOIN Otobus OB ON S.sefer_otobus_id = OB.otobus_id
                INNER JOIN Firma F ON OB.ot_firma_id = F.firma_id
                INNER JOIN Koltuk K ON B.bilet_id = K.bilet_id
                INNER JOIN Odeme O ON SA.odeme_id = O.odeme_id
                WHERE B.bilet_id = @pnr AND (Y.e_mail = @iletisim OR Y.telefon = @iletisim)
            `);

        if (result.recordset.length > 0) {
            // Bilet bulundu!
            res.json({ success: true, bilet: result.recordset[0] });
        } else {
            // Bilet yok veya iletişim bilgisi yanlış
            res.json({ success: false, message: "Bilet bulunamadı. Lütfen PNR numaranızı ve iletişim bilginizi kontrol edin." });
        }
    } catch (err) {
        console.error("Sorgulama Hatası:", err);
        res.status(500).json({ success: false, error: err.message });
    }
});

// KULLANICININ TÜM BİLETLERİNİ GETİRME API'Sİ
app.post('/api/biletlerim', async (req, res) => {
    try {
        const { email, sifre } = req.body;
        const pool = await sql.connect(dbConfig);

        // 1. Önce e-posta ve şifreyi kontrol edelim
        const authResult = await pool.request()
            .input('email', sql.VarChar(100), email)
            .input('sifre', sql.VarChar(100), sifre)
            .query(`SELECT tc_no, ad, soy_ad FROM Yolcu WHERE e_mail = @email AND sifre = @sifre`);

        if (authResult.recordset.length === 0) {
            return res.json({ success: false, message: "E-Posta veya Şifre hatalı!" });
        }

        const tcNo = authResult.recordset[0].tc_no;

        // 2. Kullanıcı doğruysa, o TC'ye ait TÜM biletleri çekelim
        const biletResult = await pool.request()
            .input('tc_no', sql.Char(11), tcNo)
            .query(`
                SELECT 
                    B.bilet_id,
                    F.firma_adi,
                    S.kalkis_sehri + ' ➔ ' + S.varis_sehri AS guzergah,
                    S.sefer_tarihi,
                    S.kalkis_saati,
                    K.koltuk_no,
                    B.fiyat
                FROM Bilet B
                INNER JOIN Satin_Alir SA ON B.bilet_id = SA.bilet_id
                INNER JOIN Sefer S ON B.sefer_id = S.sefer_id
                INNER JOIN Otobus OB ON S.sefer_otobus_id = OB.otobus_id
                INNER JOIN Firma F ON OB.ot_firma_id = F.firma_id
                INNER JOIN Koltuk K ON B.bilet_id = K.bilet_id
                WHERE SA.tc_no = @tc_no
                ORDER BY S.sefer_tarihi DESC, S.kalkis_saati DESC
            `);

        res.json({ success: true, biletler: biletResult.recordset });

    } catch (err) {
        console.error("Biletleri Getirme Hatası:", err);
        res.status(500).json({ success: false, error: err.message });
    }
});

// İADE EKRANI İÇİN BİLET DETAYINI GETİR
app.get('/api/bilet-detay/:pnr', async (req, res) => {
    try {
        const pool = await sql.connect(dbConfig);
        const result = await pool.request()
            .input('pnr', sql.Int, req.params.pnr)
            .query(`
                SELECT B.bilet_id, Y.ad + ' ' + Y.soy_ad AS yolcu, B.fiyat, 
                       S.kalkis_sehri + ' ➔ ' + S.varis_sehri AS guzergah, S.sefer_tarihi 
                FROM Bilet B
                JOIN Satin_Alir SA ON B.bilet_id = SA.bilet_id
                JOIN Yolcu Y ON SA.tc_no = Y.tc_no
                JOIN Sefer S ON B.sefer_id = S.sefer_id
                WHERE B.bilet_id = @pnr
            `);

        if(result.recordset.length > 0) res.json({ success: true, bilet: result.recordset[0] });
        else res.json({ success: false, message: "Bilet bulunamadı." });
    } catch (err) { 
        res.status(500).json({ success: false, error: err.message }); 
    }
});

// BİLET İPTAL ETME (İADE) API'Sİ
app.post('/api/iade-et', async (req, res) => {
    try {
        const { pnr } = req.body;
        const pool = await sql.connect(dbConfig);
        await pool.request()
            .input('p_bilet_id', sql.Int, parseInt(pnr))
            .execute('SP_BiletIade');
            
        res.json({ success: true, message: "İade başarılı." });
    } catch (err) { 
        console.error("İade Hatası:", err);
        res.status(500).json({ success: false, error: err.message }); 
    }
});

app.post('/api/uye-sifre-dogrula', async (req, res) => {
    try {
        const { email, sifre } = req.body;
        const pool = await sql.connect(dbConfig);
        
        // Kullanıcı tablosunda bu email ve şifreye sahip biri var mı?
        const result = await pool.request()
            .input('email', sql.VarChar, email)
            .input('sifre', sql.VarChar, sifre)
            .query("SELECT * FROM Kullanici WHERE email = @email AND sifre = @sifre");

        if (result.recordset.length > 0) {
            res.json({ success: true });
        } else {
            res.json({ success: false, message: "Üye şifreniz hatalı!" });
        }
    } catch (err) {
        res.status(500).json({ success: false, error: err.message });
    }
});

const PORT = 3000;
app.listen(PORT, () => {
    console.log(`🚀 Sistem Yayında: http://localhost:${PORT}`);
});