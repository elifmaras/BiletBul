USE [Otobus-Bilet];
GO

-- ==========================================
-- 1. TABLO OLUÞTURMA (SCHEMA)
-- ==========================================
CREATE TABLE Firma (
    firma_id INT PRIMARY KEY,
    firma_adi VARCHAR(100),
    firma_tel VARCHAR(15),
    firma_e_mail VARCHAR(100)
);

CREATE TABLE Otobus (
    otobus_id INT PRIMARY KEY,
    total_koltuk_sayisi INT,
    ot_firma_id INT,
    FOREIGN KEY (ot_firma_id) REFERENCES Firma(firma_id)
);

CREATE TABLE Sefer (
    sefer_id INT PRIMARY KEY,
    sefer_tarihi DATE,
    kalkis_saati TIME(0), -- Saat formatý güncellendi
    varis_saati TIME(0),  -- Saat formatý güncellendi
    kalkis_sehri VARCHAR(50), 
    varis_sehri VARCHAR(50),  
    peron INT,
    sefer_otobus_id INT,
    FOREIGN KEY (sefer_otobus_id) REFERENCES Otobus(otobus_id)
);

CREATE TABLE Bilet (
    bilet_id INT PRIMARY KEY,
    sefer_id INT,
    fiyat DECIMAL(10,2),
    satis_tarihi DATETIME,
    FOREIGN KEY (sefer_id) REFERENCES Sefer(sefer_id)
);

CREATE TABLE Koltuk (
    sefer_id INT,
    koltuk_no INT,
    bilet_id INT,
    PRIMARY KEY (sefer_id, koltuk_no),
    FOREIGN KEY (sefer_id) REFERENCES Sefer(sefer_id),
    FOREIGN KEY (bilet_id) REFERENCES Bilet(bilet_id)
);

CREATE TABLE Yolcu (
    tc_no CHAR(11) PRIMARY KEY,
    ad VARCHAR(50),
    soy_ad VARCHAR(50),
    cinsiyet CHAR(1),
    telefon VARCHAR(15),
    e_mail VARCHAR(100),
    sifre VARCHAR(100)
);

CREATE TABLE Kart_Bilgileri (
    kart_id INT PRIMARY KEY,
    kart_no VARCHAR(16),
    son_kullanim VARCHAR(5),
    cvc CHAR(3)
);

CREATE TABLE Odeme (
    odeme_id INT PRIMARY KEY,
    odeme_durumu VARCHAR(20),
    tutar DECIMAL(10,2),
    kart_id INT,
    FOREIGN KEY (kart_id) REFERENCES Kart_Bilgileri(kart_id)
);

CREATE TABLE Iade (
    iade_id INT PRIMARY KEY,
    iade_tutari DECIMAL(10,2),
    iade_tarihi DATETIME,
    odeme_id INT,
    FOREIGN KEY (odeme_id) REFERENCES Odeme(odeme_id)
);

CREATE TABLE Satin_Alir (
    tc_no CHAR(11),
    bilet_id INT,
    odeme_id INT,
    PRIMARY KEY (tc_no, bilet_id, odeme_id),
    FOREIGN KEY (tc_no) REFERENCES Yolcu(tc_no),
    FOREIGN KEY (bilet_id) REFERENCES Bilet(bilet_id),
    FOREIGN KEY (odeme_id) REFERENCES Odeme(odeme_id)
);
GO

-- ==========================================
-- 2. VERÝ GÝRÝÞLERÝ (DÜZENLÝ VE GRUPLU)
-- ==========================================

-- FIRMA KAYITLARI
INSERT INTO Firma (firma_id, firma_adi, firma_tel, firma_e_mail) VALUES 
(1, 'Doða Karadeniz Turizm', '04642223344', 'iletisim@dogakaradeniz.com'),
(2, 'Yeþil Rize Ekspres', '04645556677', 'destek@yesilrize.com'),
(3, 'Fýrtýna Tur', '04648889900', 'info@firtinatur.com'),
(4, 'Yýldýz Turizm', '04662121010', 'info@Yildiz.com'),
(5, 'Yýldýrým Turizm', '03462221122', 'iletisim@Yildirim.com'),
(6, 'Maraþ Turizm', '03441112233', 'info@maras.com'),
(7, 'Ýnce Turizm', '03125554433', 'info@ince.com');

-- OTOBÜS KAYITLARI
INSERT INTO Otobus (otobus_id, total_koltuk_sayisi, ot_firma_id) VALUES 
(101, 40, 1),
(102, 30, 2),
(103, 46, 3),
(104, 38, 4),
(105, 54, 5),
(106, 40, 6), 
(107, 30, 7);

-- SEFER KAYITLARI
INSERT INTO Sefer (sefer_id, sefer_tarihi, kalkis_saati, varis_saati, kalkis_sehri, varis_sehri, peron, sefer_otobus_id) VALUES 
(501, '2026-05-15', '08:00:00', '11:00:00', 'Rize', 'Trabzon', 1, 101),
(507, '2026-05-15', '10:30:00', '13:30:00', 'Rize', 'Trabzon', 3, 106),
(508, '2026-05-15', '18:00:00', '21:00:00', 'Rize', 'Trabzon', 6, 107),
(502, '2026-05-15', '14:00:00', '18:30:00', 'Trabzon', 'Artvin', 3, 102),
(503, '2026-05-16', '09:00:00', '12:00:00', 'Artvin', 'Rize', 2, 103),
(504, '2026-05-20', '22:00:00', '06:00:00', 'Rize', 'Ankara', 5, 101),
(505, '2026-05-25', '20:00:00', '04:30:00', 'Artvin', 'Sivas', 4, 104),
(506, '2026-05-26', '10:00:00', '18:00:00', 'Sivas', 'Rize', 2, 105);

 UPDATE Sefer SET sefer_otobus_id = 106 WHERE sefer_id = 507;
 UPDATE Sefer SET sefer_otobus_id = 107 WHERE sefer_id = 508;

-- YOLCU KAYITLARI
INSERT INTO Yolcu (tc_no, ad, soy_ad, cinsiyet, telefon, e_mail, sifre) VALUES 
('11122233344', 'Ali', 'Çay', 'E', '05321112233', 'ali@email.com', 'sifre123'),
('55566677788', 'Ayþe', 'Fýndýk', 'K', '05445556677', 'ayse@email.com', 'ayse456'),
('99900011122', 'Zeynep', 'Dere', 'K', '05051112299', 'zeynep@email.com', 'zeynep789'),
('22233344455', 'Murat', 'Yýlmaz', 'E', '05332223344', 'murat@email.com', 'sifre123'),
('33344455566', 'Elif', 'Kaya', 'K', '05443334455', 'elif@email.com', 'elif456'),
('44455566677', 'Burak', 'Demir', 'E', '05054445566', 'burak@email.com', 'burak789'),
('55511122233', 'Selin', 'Yýlmaz', 'K', '05331112233', 'selin@email.com', '123'),
('66622233344', 'Ahmet', 'Kaya', 'E', '05442223344', 'ahmet@email.com', '123'),
('77733344455', 'Merve', 'Demir', 'K', '05053334455', 'merve@email.com', '123'),
('88844455566', 'Can', 'Yýldýz', 'E', '05554445566', 'can@email.com', '123');

-- KART BÝLGÝLERÝ KAYITLARI
INSERT INTO Kart_Bilgileri (kart_id, kart_no, son_kullanim, cvc) VALUES 
(201, '1234567812345678', '05/29', '123'),
(202, '8765432187654321', '12/27', '456'),
(203, '1111222233334444', '08/30', '999'),
(204, '5555666677778888', '11/28', '777');

-- ÖDEME KAYITLARI
INSERT INTO Odeme (odeme_id, odeme_durumu, tutar, kart_id) VALUES 
(3001, 'Onaylandý', 250.00, 201),
(3002, 'Onaylandý', 850.00, 202),
(4001, 'Onaylandý', 300.00, 203),
(4002, 'Onaylandý', 300.00, 204);

-- BÝLET KAYITLARI
INSERT INTO Bilet (bilet_id, sefer_id, fiyat, satis_tarihi) VALUES 
(1001, 501, 250.00, '2026-04-10 10:30:00'),
(1002, 501, 250.00, '2026-04-10 11:15:00'),
(1003, 504, 850.00, '2026-04-12 15:00:00'),
(9999, 501, 500.00, GETDATE()),
(2026, 502, 300.00, GETDATE()),
(3001, 507, 300.00, GETDATE()),
(3002, 507, 300.00, GETDATE()),
(3004, 508, 300.00, GETDATE()),
(3005, 508, 300.00, GETDATE()),
(5001, 507, 300.00, GETDATE()),
(5002, 507, 300.00, GETDATE()),
(5003, 507, 300.00, GETDATE()),
(5004, 507, 300.00, GETDATE()),
(6001, 508, 300.00, GETDATE()),
(6002, 508, 300.00, GETDATE()),
(6003, 508, 300.00, GETDATE());

-- KOLTUK KAYITLARI (Bilet Eþleþmeleri)
INSERT INTO Koltuk (sefer_id, koltuk_no, bilet_id) VALUES 
(501, 1, 1001),
(501, 2, 1002),
(501, 50, 9999),
(502, 1, NULL),
(504, 15, 1003),
(507, 1, 3001),
(507, 2, 3002),
(507, 7, 5001),
(507, 12, 5002),
(507, 18, 5003),
(507, 25, 5004),
(508, 3, 6001),
(508, 5, 3004),
(508, 6, 3005),
(508, 14, 6002),
(508, 22, 6003);

-- SATIN ALMA ÝLÝÞKÝSÝ 
INSERT INTO Satin_Alir (tc_no, bilet_id, odeme_id) VALUES 
('11122233344', 1001, 3001),
('11122233344', 9999, 3001),
('55566677788', 1003, 3002),
('22233344455', 3001, 4001), -- Murat (Erkek)
('55566677788', 3002, 4001), -- Ayþe (Kadýn)
('33344455566', 3004, 4002), -- Elif (Kadýn)
('55511122233', 5001, 4001), -- Selin (Kadýn)
('66622233344', 5002, 4001), -- Ahmet (Erkek)
('77733344455', 5003, 4002); -- Merve (Kadýn)
GO

-- ==========================================
-- 3. PROCEDURE, TRIGGER VE VIEW'LAR
-- ==========================================

-- Sefer Arama Procedure
CREATE PROCEDURE UygunSeferleriListele
    @p_kalkis VARCHAR(50), 
    @p_varis VARCHAR(50), 
    @p_tarih DATE
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        S.sefer_id AS [Sefer No], 
        F.firma_adi AS [Firma Adý], 
        S.kalkis_saati AS [Kalkýþ], 
        S.varis_saati AS [Varýþ], 
        S.peron AS [Peron],
        O.total_koltuk_sayisi AS [Kapasite]
    FROM Sefer S
    INNER JOIN Otobus O ON S.sefer_otobus_id = O.otobus_id
    INNER JOIN Firma F ON O.ot_firma_id = F.firma_id
    WHERE S.kalkis_sehri = @p_kalkis 
      AND S.varis_sehri = @p_varis 
      AND S.sefer_tarihi = @p_tarih;
END;
GO

-- Koltuk Güncelleme Trigger
CREATE TRIGGER KoltukDurumGuncelle
ON Bilet
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE K
    SET K.bilet_id = i.bilet_id
    FROM Koltuk K
    INNER JOIN inserted i ON K.sefer_id = i.sefer_id
    WHERE K.koltuk_no = (
        SELECT TOP 1 koltuk_no 
        FROM Koltuk 
        WHERE sefer_id = i.sefer_id AND bilet_id IS NULL
        ORDER BY koltuk_no ASC
    );
END;
GO

-- Bilet Detay View
CREATE VIEW Bilet_Detay_Sade_View AS
SELECT 
    (Y.ad + ' ' + Y.soy_ad) AS Yolcu,
    F.firma_adi            AS Firma,
    S.kalkis_sehri + '-' + S.varis_sehri AS Rota,
    S.sefer_tarihi         AS Tarih,
    S.kalkis_saati         AS Saat,
    K.koltuk_no            AS Koltuk,
    B.fiyat                AS Tutar
FROM Yolcu Y, Satin_Alir SA, Bilet B, Sefer S, Otobus O, Firma F, Koltuk K
WHERE Y.tc_no = SA.tc_no 
  AND SA.bilet_id = B.bilet_id 
  AND B.sefer_id = S.sefer_id 
  AND S.sefer_otobus_id = O.otobus_id 
  AND O.ot_firma_id = F.firma_id 
  AND B.bilet_id = K.bilet_id;
GO



USE [Otobus-Bilet];
GO

CREATE PROCEDURE SP_BiletSatinAl
    @p_tc_no CHAR(11),
    @p_ad VARCHAR(50),
    @p_soy_ad VARCHAR(50),
    @p_cinsiyet CHAR(1),
    @p_kart_no VARCHAR(16),
    @p_skt VARCHAR(5),
    @p_cvc CHAR(3),
    @p_sefer_id INT,
    @p_koltuk_no INT,
    @p_fiyat DECIMAL(10,2)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. YOLCU KONTROLÜ (Eðer sisteme ilk kez giriyorsa kaydet)
        IF NOT EXISTS (SELECT 1 FROM Yolcu WHERE tc_no = @p_tc_no)
        BEGIN
            INSERT INTO Yolcu (tc_no, ad, soy_ad, cinsiyet, telefon, e_mail, sifre)
            VALUES (@p_tc_no, @p_ad, @p_soy_ad, @p_cinsiyet, 'Belirtilmedi', @p_tc_no+'@biletbul.com', '1234');
        END

        -- 2. KART KONTROLÜ (Daha önce yoksa kaydet)
        DECLARE @v_kart_id INT;
        SELECT @v_kart_id = kart_id FROM Kart_Bilgileri WHERE kart_no = @p_kart_no;

        IF @v_kart_id IS NULL
        BEGIN
            SELECT @v_kart_id = ISNULL(MAX(kart_id), 200) + 1 FROM Kart_Bilgileri;
            INSERT INTO Kart_Bilgileri (kart_id, kart_no, son_kullanim, cvc)
            VALUES (@v_kart_id, @p_kart_no, @p_skt, @p_cvc);
        END

        -- 3. ÖDEMEYÝ AL
        DECLARE @v_odeme_id INT;
        SELECT @v_odeme_id = ISNULL(MAX(odeme_id), 4000) + 1 FROM Odeme;
        INSERT INTO Odeme (odeme_id, odeme_durumu, tutar, kart_id)
        VALUES (@v_odeme_id, 'Onaylandý', @p_fiyat, @v_kart_id);

        -- 4. BÝLETÝ KES
        DECLARE @v_bilet_id INT;
        SELECT @v_bilet_id = ISNULL(MAX(bilet_id), 7000) + 1 FROM Bilet;
        INSERT INTO Bilet (bilet_id, sefer_id, fiyat, satis_tarihi)
        VALUES (@v_bilet_id, @p_sefer_id, @p_fiyat, GETDATE());

        -- 5. KOLTUÐU REZERVE ET
        INSERT INTO Koltuk (sefer_id, koltuk_no, bilet_id)
        VALUES (@p_sefer_id, @p_koltuk_no, @v_bilet_id);

        -- 6. SATIN ALMA ÝLÝÞKÝSÝNÝ KUR (Bileti, Yolcuya ve Ödemeye Baðla)
        INSERT INTO Satin_Alir (tc_no, bilet_id, odeme_id)
        VALUES (@p_tc_no, @v_bilet_id, @v_odeme_id);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMsg, 16, 1);
    END CATCH
END;
GO

-- KULLANICIN ÜYE GÝRÝÞÝ YOKSA HATA MESAJI FIRLATMASI ÝÇÝN ALTER PROCEDURE
USE [Otobus-Bilet];
GO

ALTER PROCEDURE SP_BiletSatinAl
    @p_tc_no CHAR(11),
    @p_ad VARCHAR(50),
    @p_soy_ad VARCHAR(50),
    @p_cinsiyet CHAR(1),
    @p_kart_no VARCHAR(16),
    @p_skt VARCHAR(5),
    @p_cvc CHAR(3),
    @p_sefer_id INT,
    @p_koltuk_no INT,
    @p_fiyat DECIMAL(10,2)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. GÜVENLÝK KONTROLÜ (Sadece kayýtlý üyeler bilet alabilir!)
        IF NOT EXISTS (SELECT 1 FROM Yolcu WHERE tc_no = @p_tc_no)
        BEGIN
            -- Eðer TC veritabanýnda (Yolcu tablosunda) yoksa, özel bir hata fýrlat ve iþlemi durdur.
            RAISERROR('Sadece sisteme kayýtlý üyeler bilet alabilir! Lütfen geçerli bir TC Kimlik No giriniz.', 16, 1);
        END

        -- 2. KART KONTROLÜ (Yeni kartla ödeme yapabilirler, kartý sisteme kaydederiz)
        DECLARE @v_kart_id INT;
        SELECT @v_kart_id = kart_id FROM Kart_Bilgileri WHERE kart_no = @p_kart_no;

        IF @v_kart_id IS NULL
        BEGIN
            SELECT @v_kart_id = ISNULL(MAX(kart_id), 200) + 1 FROM Kart_Bilgileri;
            INSERT INTO Kart_Bilgileri (kart_id, kart_no, son_kullanim, cvc)
            VALUES (@v_kart_id, @p_kart_no, @p_skt, @p_cvc);
        END

        -- 3. ÖDEMEYÝ AL
        DECLARE @v_odeme_id INT;
        SELECT @v_odeme_id = ISNULL(MAX(odeme_id), 4000) + 1 FROM Odeme;
        INSERT INTO Odeme (odeme_id, odeme_durumu, tutar, kart_id)
        VALUES (@v_odeme_id, 'Onaylandý', @p_fiyat, @v_kart_id);

        -- 4. BÝLETÝ KES
        DECLARE @v_bilet_id INT;
        SELECT @v_bilet_id = ISNULL(MAX(bilet_id), 7000) + 1 FROM Bilet;
        INSERT INTO Bilet (bilet_id, sefer_id, fiyat, satis_tarihi)
        VALUES (@v_bilet_id, @p_sefer_id, @p_fiyat, GETDATE());

        -- 5. KOLTUÐU REZERVE ET
        INSERT INTO Koltuk (sefer_id, koltuk_no, bilet_id)
        VALUES (@p_sefer_id, @p_koltuk_no, @v_bilet_id);

        -- 6. SATIN ALMA ÝLÝÞKÝSÝNÝ KUR
        INSERT INTO Satin_Alir (tc_no, bilet_id, odeme_id)
        VALUES (@p_tc_no, @v_bilet_id, @v_odeme_id);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION; -- Hata olursa hiçbir þeyi kaydetme, geri al!
        
        DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMsg, 16, 1);
    END CATCH
END;
GO


--ÝADE KODLARI
USE [Otobus-Bilet];
GO

CREATE PROCEDURE SP_BiletIade
    @p_bilet_id INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @v_odeme_id INT;
        SELECT @v_odeme_id = odeme_id FROM Satin_Alir WHERE bilet_id = @p_bilet_id;

        -- 1. Ödemeyi "Ýade Edildi" olarak güncelle ki muhasebe kaydýmýz dursun
        UPDATE Odeme SET odeme_durumu = 'Ýade Edildi' WHERE odeme_id = @v_odeme_id;

        -- 2. Koltuðu boþa çýkar (Baþka müþteri alabilsin diye)
        DELETE FROM Koltuk WHERE bilet_id = @p_bilet_id;

        -- 3. Satýn alma iliþkisini kopar ve bileti sil
        DELETE FROM Satin_Alir WHERE bilet_id = @p_bilet_id;
        DELETE FROM Bilet WHERE bilet_id = @p_bilet_id;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMsg, 16, 1);
    END CATCH
END;
GO

--ÝADE TABLOSU OLUÞMASI ÝÇÝN TRANSACTÝON güncellenmiþ
USE [Otobus-Bilet];
GO

ALTER PROCEDURE SP_BiletIade
    @p_bilet_id INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @v_odeme_id INT;
        DECLARE @v_tutar DECIMAL(10,2);

        -- 1. Ýade edilecek biletin ödeme ID'sini ve ödenen tutarý bulalým
        SELECT @v_odeme_id = odeme_id FROM Satin_Alir WHERE bilet_id = @p_bilet_id;
        SELECT @v_tutar = tutar FROM Odeme WHERE odeme_id = @v_odeme_id;

        -- 2. ÝADE tablosuna kaydýmýzý ekleyelim (Eksik olan ve tablonun boþ kalmasýna sebep olan kýsým)
        DECLARE @v_iade_id INT;
        SELECT @v_iade_id = ISNULL(MAX(iade_id), 8000) + 1 FROM Iade; -- ID'yi otomatik artýr

        INSERT INTO Iade (iade_id, iade_tutari, iade_tarihi, odeme_id)
        VALUES (@v_iade_id, @v_tutar, GETDATE(), @v_odeme_id);

        -- 3. Ödemeyi "Ýade Edildi" olarak güncelle ki muhasebe kaydýmýz dursun
        UPDATE Odeme SET odeme_durumu = 'Ýade Edildi' WHERE odeme_id = @v_odeme_id;

        -- 4. Koltuðu boþa çýkar (Baþka müþteri alabilsin diye bilet_id'yi NULL yapýyoruz)
        -- DÝKKAT: Delete yerine Update yapýyoruz ki koltuk numaramýz sistemde fiziksel olarak kalmaya devam etsin, sadece boþalsýn.
        UPDATE Koltuk SET bilet_id = NULL WHERE bilet_id = @p_bilet_id;

        -- DÝKKAT: Bilet ve Satin_Alir tablolarýndan DELETE yapmýyoruz!
        -- Bilet sistemde duracak, sadece ödeme durumu "Ýade Edildi" olduðu için iade edildiðini anlayacaðýz.

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMsg, 16, 1);
    END CATCH
END;
GO



--GÜNCEL ÜYELERÝN AD SOYAD TC MAÝL SÝFRE BÝLGÝLERÝ
USE [Otobus-Bilet];
GO

SELECT 
    ad AS [Ad], 
    soy_ad AS [Soyad], 
    tc_no AS [TC No], 
    e_mail AS [E-Posta], 
    sifre AS [Þifre]
FROM Yolcu;





--ÝADE EDÝLEN BÝLETLER
SELECT 
    I.iade_id AS [Ýade Ýþlem No],
    I.iade_tutari AS [Ýade Tutarý],
    I.iade_tarihi AS [Ýade Tarihi],
    Y.ad + ' ' + Y.soy_ad AS [Yolcu Adý Soyadý],
    Y.tc_no AS [TC Kimlik],
    B.bilet_id AS [Ýptal Edilen PNR],
    O.odeme_durumu AS [Ödeme Son Durum]
FROM Iade I
JOIN Odeme O ON I.odeme_id = O.odeme_id
JOIN Satin_Alir SA ON O.odeme_id = SA.odeme_id
JOIN Yolcu Y ON SA.tc_no = Y.tc_no
JOIN Bilet B ON SA.bilet_id = B.bilet_id
ORDER BY I.iade_tarihi DESC;





--KÝM HANGÝ BÝLETÝ ALMIÞ SORGUSU
USE [Otobus-Bilet];
GO

SELECT 
    B.bilet_id AS [PNR Kodu],
    Y.ad + ' ' + Y.soy_ad AS [Yolcu Adý],
    Y.e_mail AS [E-Posta],
    F.firma_adi AS [Firma],
    S.kalkis_sehri + ' - ' + S.varis_sehri AS [Güzergah],
    S.sefer_tarihi AS [Tarih],
    S.kalkis_saati AS [Saat],
    K.koltuk_no AS [Koltuk No],
    B.fiyat AS [Ödenen Tutar]
FROM Bilet B
INNER JOIN Satin_Alir SA ON B.bilet_id = SA.bilet_id
INNER JOIN Yolcu Y ON SA.tc_no = Y.tc_no
INNER JOIN Koltuk K ON B.bilet_id = K.bilet_id
INNER JOIN Sefer S ON B.sefer_id = S.sefer_id
INNER JOIN Otobus OB ON S.sefer_otobus_id = OB.otobus_id
INNER JOIN Firma F ON OB.ot_firma_id = F.firma_id
ORDER BY B.bilet_id DESC;




--PNR KODLARI VE EÞLEÞTÝKLERÝ E-POSTALAR SORGUSU
USE [Otobus-Bilet];
GO
SELECT TOP 5 B.bilet_id AS [BÝLETÝN PNR KODU], Y.e_mail AS [EÞLEÞEN E-POSTA]
FROM Bilet B
JOIN Satin_Alir SA ON B.bilet_id = SA.bilet_id
JOIN Yolcu Y ON SA.tc_no = Y.tc_no
ORDER BY B.satis_tarihi DESC;





-- EN SON SATILANDAN ÝLK SATILANA DOÐRU BÝLETLERÝN TEST KODU
USE [Otobus-Bilet];
GO

SELECT TOP 5
    Y.ad AS [Yolcu Adý], 
    Y.soy_ad AS [Soyadý], 
    Y.tc_no AS [TC Kimlik], 
    Y.cinsiyet AS [Cinsiyet],
    K.koltuk_no AS [Koltuk No],
    O.tutar AS [Ödenen Tutar], 
    KB.kart_no AS [Kullanýlan Kart]
FROM Satin_Alir SA
JOIN Yolcu Y ON SA.tc_no = Y.tc_no
JOIN Bilet B ON SA.bilet_id = B.bilet_id
JOIN Koltuk K ON B.bilet_id = K.bilet_id
JOIN Odeme O ON SA.odeme_id = O.odeme_id
JOIN Kart_Bilgileri KB ON O.kart_id = KB.kart_id
ORDER BY B.satis_tarihi DESC;


