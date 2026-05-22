-- ============================================================
--  VTYS-1 Dönem Projesi: Çevrimiçi Yemek Sipariş Platformu
--  Microsoft SQL Server (T-SQL) için hazırlanmıştır.
--  Veritabanı: YemekSiparisDB
-- ============================================================

-- ============================================================
-- 0. VERİTABANI OLUŞTURMA
-- ============================================================
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'YemekSiparisDB')
    CREATE DATABASE YemekSiparisDB;
GO

USE YemekSiparisDB;
GO

-- ============================================================
-- 1. TABLO OLUŞTURMA (DDL)
-- ============================================================

-- ---------------------------------------------------------------
-- 1.1 Roller (Müşteri, Kurye, Admin vb.)
-- ---------------------------------------------------------------
CREATE TABLE Roller (
    RolID       INT IDENTITY(1,1) PRIMARY KEY,
    RolAdi      NVARCHAR(50) NOT NULL UNIQUE,
    Aciklama    NVARCHAR(200)
);
GO

-- ---------------------------------------------------------------
-- 1.2 Kullanıcılar
-- ---------------------------------------------------------------
CREATE TABLE Kullanicilar (
    KullaniciID     INT IDENTITY(1,1) PRIMARY KEY,
    RolID           INT NOT NULL,
    Ad              NVARCHAR(100) NOT NULL,
    Soyad           NVARCHAR(100) NOT NULL,
    Eposta          NVARCHAR(150) NOT NULL UNIQUE,
    Telefon         NVARCHAR(20)  NOT NULL UNIQUE,
    SifreHash       NVARCHAR(255) NOT NULL,
    AdresBilgisi    NVARCHAR(500),
    -- "Askıda Yemek" havuzundan yararlanabilmesi için doğrulanmış mı?
    IhtiyacDogrulamasi BIT NOT NULL DEFAULT 0,
    -- Soft Delete
    IsActive        BIT NOT NULL DEFAULT 1,
    KayitTarihi     DATETIME NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_Kullanici_Rol FOREIGN KEY (RolID) REFERENCES Roller(RolID),
    CONSTRAINT CHK_Eposta CHECK (Eposta LIKE '%@%.%')
);
GO

-- ---------------------------------------------------------------
-- 1.3 Restoranlar
-- ---------------------------------------------------------------
CREATE TABLE Restoranlar (
    RestoranID      INT IDENTITY(1,1) PRIMARY KEY,
    RestoranAdi     NVARCHAR(200) NOT NULL,
    Adres           NVARCHAR(500) NOT NULL,
    Telefon         NVARCHAR(20)  NOT NULL UNIQUE,
    Eposta          NVARCHAR(150) UNIQUE,
    Puan            DECIMAL(3,2)  NOT NULL DEFAULT 0,
    ToplamCiro      DECIMAL(14,2) NOT NULL DEFAULT 0,
    IsActive        BIT           NOT NULL DEFAULT 1,
    AcilisTarihi    DATE,

    CONSTRAINT CHK_Puan CHECK (Puan BETWEEN 0 AND 5)
);
GO

-- ---------------------------------------------------------------
-- 1.4 Kategoriler (Pizza, Burger, Tatlı…)
-- ---------------------------------------------------------------
CREATE TABLE Kategoriler (
    KategoriID   INT IDENTITY(1,1) PRIMARY KEY,
    KategoriAdi  NVARCHAR(100) NOT NULL UNIQUE
);
GO

-- ---------------------------------------------------------------
-- 1.5 Menü Ürünleri
-- ---------------------------------------------------------------
CREATE TABLE MenuUrunleri (
    UrunID       INT IDENTITY(1,1) PRIMARY KEY,
    RestoranID   INT            NOT NULL,
    KategoriID   INT,
    UrunAdi      NVARCHAR(200)  NOT NULL,
    Aciklama     NVARCHAR(500),
    Fiyat        DECIMAL(10,2)  NOT NULL,
    IsActive     BIT            NOT NULL DEFAULT 1,

    CONSTRAINT FK_Urun_Restoran  FOREIGN KEY (RestoranID)  REFERENCES Restoranlar(RestoranID),
    CONSTRAINT FK_Urun_Kategori  FOREIGN KEY (KategoriID)  REFERENCES Kategoriler(KategoriID),
    CONSTRAINT CHK_Fiyat CHECK (Fiyat > 0)
);
GO

-- ---------------------------------------------------------------
-- 1.6 Siparişler
-- ---------------------------------------------------------------
CREATE TABLE Siparisler (
    SiparisID       INT IDENTITY(1,1) PRIMARY KEY,
    KullaniciID     INT           NOT NULL,
    RestoranID      INT           NOT NULL,
    SiparisTarihi   DATETIME      NOT NULL DEFAULT GETDATE(),
    ToplamTutar     DECIMAL(10,2) NOT NULL DEFAULT 0,
    -- Durum: Beklemede, Hazırlanıyor, Yolda, TeslimEdildi, İptalEdildi
    Durum           NVARCHAR(50)  NOT NULL DEFAULT 'Beklemede',
    -- Bu sipariş "Askıda Yemek" havuzundan karşılandı mı?
    AskidaYemekKullanildi BIT    NOT NULL DEFAULT 0,
    IsActive        BIT           NOT NULL DEFAULT 1,

    CONSTRAINT FK_Siparis_Kullanici FOREIGN KEY (KullaniciID) REFERENCES Kullanicilar(KullaniciID),
    CONSTRAINT FK_Siparis_Restoran  FOREIGN KEY (RestoranID)  REFERENCES Restoranlar(RestoranID),
    CONSTRAINT CHK_ToplamTutar CHECK (ToplamTutar >= 0)
);
GO

-- ---------------------------------------------------------------
-- 1.7 Sipariş Detayları
-- ---------------------------------------------------------------
CREATE TABLE SiparisDetaylari (
    DetayID     INT IDENTITY(1,1) PRIMARY KEY,
    SiparisID   INT           NOT NULL,
    UrunID      INT           NOT NULL,
    Adet        INT           NOT NULL DEFAULT 1,
    BirimFiyat  DECIMAL(10,2) NOT NULL,

    CONSTRAINT FK_Detay_Siparis FOREIGN KEY (SiparisID) REFERENCES Siparisler(SiparisID),
    CONSTRAINT FK_Detay_Urun    FOREIGN KEY (UrunID)    REFERENCES MenuUrunleri(UrunID),
    CONSTRAINT CHK_Adet CHECK (Adet > 0),
    CONSTRAINT CHK_BirimFiyat CHECK (BirimFiyat > 0)
);
GO

-- ---------------------------------------------------------------
-- 1.8 Kuryeler
-- ---------------------------------------------------------------
CREATE TABLE Kuryeler (
    KuryeID         INT IDENTITY(1,1) PRIMARY KEY,
    KullaniciID     INT           NOT NULL UNIQUE,   -- Kullanicilar tablosuna bağlı
    PlakaNo         NVARCHAR(20),
    ToplamTeslimat  INT           NOT NULL DEFAULT 0,
    IsActive        BIT           NOT NULL DEFAULT 1,

    CONSTRAINT FK_Kurye_Kullanici FOREIGN KEY (KullaniciID) REFERENCES Kullanicilar(KullaniciID)
);
GO

-- ---------------------------------------------------------------
-- 1.9 Sipariş - Kurye Ataması
-- ---------------------------------------------------------------
CREATE TABLE SiparisKuryeAtama (
    AtamaID         INT IDENTITY(1,1) PRIMARY KEY,
    SiparisID       INT      NOT NULL UNIQUE,
    KuryeID         INT      NOT NULL,
    AtamaTarihi     DATETIME NOT NULL DEFAULT GETDATE(),
    TeslimTarihi    DATETIME,

    CONSTRAINT FK_Atama_Siparis FOREIGN KEY (SiparisID) REFERENCES Siparisler(SiparisID),
    CONSTRAINT FK_Atama_Kurye   FOREIGN KEY (KuryeID)   REFERENCES Kuryeler(KuryeID)
);
GO

-- ---------------------------------------------------------------
-- 1.10 ÖZEL MODÜL: Askıda Yemek Havuzu
--       Her bağış ayrı satır olarak kaydedilir (bağışçı gizli olabilir).
--       Bakiye bu tablodaki aktif (KullanildiMi=0) satırların toplamıdır.
-- ---------------------------------------------------------------
CREATE TABLE AskidaYemekHavuzu (
    HavuzID         INT IDENTITY(1,1) PRIMARY KEY,
    BagisciID       INT           NULL,   -- NULL = anonim bağış
    BagisTutari     DECIMAL(10,2) NOT NULL,
    BagisAciklama   NVARCHAR(300),
    BagisTarihi     DATETIME      NOT NULL DEFAULT GETDATE(),
    -- Bu bağış kullanıldı mı?
    KullanildiMi    BIT           NOT NULL DEFAULT 0,
    -- Hangi sipariş tarafından kullanıldı?
    KullananSiparisID INT         NULL,

    CONSTRAINT FK_Havuz_Bagisci FOREIGN KEY (BagisciID)
        REFERENCES Kullanicilar(KullaniciID),
    CONSTRAINT FK_Havuz_Siparis FOREIGN KEY (KullananSiparisID)
        REFERENCES Siparisler(SiparisID),
    CONSTRAINT CHK_BagisTutar CHECK (BagisTutari > 0)
);
GO

-- ---------------------------------------------------------------
-- 1.11 Değerlendirmeler (Restoran puanı)
-- ---------------------------------------------------------------
CREATE TABLE Degerlendirmeler (
    DegerlendirmeID INT IDENTITY(1,1) PRIMARY KEY,
    SiparisID       INT NOT NULL UNIQUE,
    KullaniciID     INT NOT NULL,
    RestoranID      INT NOT NULL,
    Puan            TINYINT NOT NULL,
    Yorum           NVARCHAR(500),
    TarihSaat       DATETIME NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_Deg_Siparis   FOREIGN KEY (SiparisID)   REFERENCES Siparisler(SiparisID),
    CONSTRAINT FK_Deg_Kullanici FOREIGN KEY (KullaniciID) REFERENCES Kullanicilar(KullaniciID),
    CONSTRAINT FK_Deg_Restoran  FOREIGN KEY (RestoranID)  REFERENCES Restoranlar(RestoranID),
    CONSTRAINT CHK_DegPuan CHECK (Puan BETWEEN 1 AND 5)
);
GO

-- ============================================================
-- 2. İNDEKSLER (Primary Key dışında, sık aranan kolonlar)
-- ============================================================

-- Siparişler tablosunda müşteriye göre hızlı arama
CREATE NONCLUSTERED INDEX IX_Siparisler_KullaniciID
    ON Siparisler(KullaniciID);
GO

-- MenuUrunleri tablosunda restorana göre hızlı arama
CREATE NONCLUSTERED INDEX IX_MenuUrunleri_RestoranID
    ON MenuUrunleri(RestoranID);
GO

-- Askıda Yemek: kullanılmayan bağışları hızlı bulmak için
CREATE NONCLUSTERED INDEX IX_AskidaHavuz_KullanildiMi
    ON AskidaYemekHavuzu(KullanildiMi)
    INCLUDE (BagisTutari);
GO

-- Kullanıcı girişi için e-posta araması
CREATE NONCLUSTERED INDEX IX_Kullanicilar_Eposta
    ON Kullanicilar(Eposta);
GO

-- ============================================================
-- 3. GÖRÜNÜMLER (VIEW)
-- ============================================================

-- 3.1 Aktif Restoran Menüleri
CREATE OR ALTER VIEW vw_AktifRestoranMenuleri AS
    SELECT
        r.RestoranID,
        r.RestoranAdi,
        k.KategoriAdi,
        m.UrunID,
        m.UrunAdi,
        m.Aciklama,
        m.Fiyat
    FROM MenuUrunleri m
    INNER JOIN Restoranlar r ON m.RestoranID = r.RestoranID
    LEFT  JOIN Kategoriler k ON m.KategoriID = k.KategoriID
    WHERE m.IsActive = 1
      AND r.IsActive = 1;
GO

-- 3.2 Askıda Yemek Havuz Durumu (Mevcut bakiye ve bağış sayısı)
CREATE OR ALTER VIEW vw_AskidaYemekHavuzDurumu AS
    SELECT
        COUNT(*)                    AS ToplamBagisSayisi,
        SUM(BagisTutari)            AS ToplamBagisEdilen,
        SUM(CASE WHEN KullanildiMi = 0 THEN BagisTutari ELSE 0 END) AS MevcutBakiye,
        SUM(CASE WHEN KullanildiMi = 1 THEN BagisTutari ELSE 0 END) AS KullanilanTutar
    FROM AskidaYemekHavuzu;
GO

-- 3.3 Teslim Edilen Siparişlerin Özeti
CREATE OR ALTER VIEW vw_TeslimEdilmisSiparisler AS
    SELECT
        s.SiparisID,
        k.Ad + ' ' + k.Soyad AS MusteriAdi,
        r.RestoranAdi,
        s.SiparisTarihi,
        s.ToplamTutar,
        s.AskidaYemekKullanildi
    FROM Siparisler s
    INNER JOIN Kullanicilar k ON s.KullaniciID = k.KullaniciID
    INNER JOIN Restoranlar  r ON s.RestoranID  = r.RestoranID
    WHERE s.Durum = 'TeslimEdildi'
      AND s.IsActive = 1;
GO

-- ============================================================
-- 4. TETİKLEYİCİLER (TRIGGER)
-- ============================================================

-- 4.1 Sipariş "TeslimEdildi" olduğunda restoranın ToplamCiro'sunu güncelle
CREATE OR ALTER TRIGGER trg_SiparisTeslimEdildi
ON Siparisler
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Sadece Durum = 'TeslimEdildi' olan güncellemeler için çalışır
    IF UPDATE(Durum)
    BEGIN
        UPDATE r
        SET r.ToplamCiro = r.ToplamCiro + i.ToplamTutar
        FROM Restoranlar r
        INNER JOIN inserted  i ON r.RestoranID = i.RestoranID
        INNER JOIN deleted   d ON i.SiparisID  = d.SiparisID
        WHERE i.Durum = 'TeslimEdildi'
          AND d.Durum <> 'TeslimEdildi';
    END
END;
GO

-- 4.2 Askıda Yemek ile sipariş verildiğinde havuz bakiyesini otomatik düş
--     Mantık: Havuzdaki en eski kullanılmamış bağışı işaretle
CREATE OR ALTER TRIGGER trg_AskidaYemekKullanimi
ON Siparisler
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Yeni eklenen veya güncellenen siparişlerde AskidaYemekKullanildi = 1 olanları bul
    IF EXISTS (
        SELECT 1 FROM inserted i
        WHERE i.AskidaYemekKullanildi = 1
    )
    BEGIN
        -- Her uygun sipariş için en eski aktif bağışı bul ve kullan
        UPDATE TOP(1) ayh
        SET
            ayh.KullanildiMi      = 1,
            ayh.KullananSiparisID = i.SiparisID
        FROM AskidaYemekHavuzu ayh
        CROSS JOIN (
            SELECT TOP(1) SiparisID, ToplamTutar
            FROM inserted
            WHERE AskidaYemekKullanildi = 1
            ORDER BY SiparisID
        ) i
        WHERE ayh.KullanildiMi = 0
          AND ayh.BagisTutari  >= i.ToplamTutar;
    END
END;
GO

-- 4.3 Değerlendirme eklendiğinde restoranın ortalama puanını güncelle
CREATE OR ALTER TRIGGER trg_PuanGuncelle
ON Degerlendirmeler
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE r
    SET r.Puan = (
        SELECT AVG(CAST(d.Puan AS DECIMAL(3,2)))
        FROM Degerlendirmeler d
        WHERE d.RestoranID = r.RestoranID
    )
    FROM Restoranlar r
    INNER JOIN inserted i ON r.RestoranID = i.RestoranID;
END;
GO
-- ============================================================
-- 5. TEST VERİLERİ (DML - INSERT INTO)
-- ============================================================

-- 5.1 Roller
INSERT INTO Roller (RolAdi, Aciklama) VALUES
    ('Musteri', 'Platformdan sipariş veren kullanıcı'),
    ('Kurye',   'Siparişleri teslim eden kullanıcı'),
    ('Admin',   'Platform yöneticisi');
GO

-- 5.2 Kullanıcılar (20 müşteri + 3 kurye + 1 admin)
INSERT INTO Kullanicilar (RolID, Ad, Soyad, Eposta, Telefon, SifreHash, AdresBilgisi, IhtiyacDogrulamasi, IsActive) VALUES
(1, 'Ahmet',   'Yılmaz',   'ahmet.yilmaz@mail.com',   '05301110001', 'hash1',  'Konya, Selçuklu',        0, 1),
(1, 'Fatma',   'Kaya',     'fatma.kaya@mail.com',     '05301110002', 'hash2',  'Konya, Meram',           1, 1),  -- ihtiyaç sahibi
(1, 'Mehmet',  'Demir',    'mehmet.demir@mail.com',   '05301110003', 'hash3',  'Konya, Karatay',         0, 1),
(1, 'Ayşe',    'Çelik',    'ayse.celik@mail.com',     '05301110004', 'hash4',  'Konya, Selçuklu',        1, 1),  -- ihtiyaç sahibi
(1, 'Mustafa', 'Şahin',    'mustafa.sahin@mail.com',  '05301110005', 'hash5',  'Konya, Meram',           0, 1),
(1, 'Zeynep',  'Arslan',   'zeynep.arslan@mail.com',  '05301110006', 'hash6',  'Konya, Karatay',         0, 1),
(1, 'İbrahim', 'Koç',      'ibrahim.koc@mail.com',    '05301110007', 'hash7',  'Ankara, Çankaya',        0, 1),
(1, 'Elif',    'Kurt',     'elif.kurt@mail.com',      '05301110008', 'hash8',  'İstanbul, Kadıköy',      1, 1),  -- ihtiyaç sahibi
(1, 'Hasan',   'Özdemir',  'hasan.ozdemir@mail.com',  '05301110009', 'hash9',  'İzmir, Bornova',         0, 1),
(1, 'Merve',   'Doğan',    'merve.dogan@mail.com',    '05301110010', 'hash10', 'Ankara, Keçiören',       0, 1),
(1, 'Can',     'Polat',    'can.polat@mail.com',      '05301110011', 'hash11', 'Konya, Selçuklu',        0, 1),
(1, 'Selin',   'Erdoğan',  'selin.erdogan@mail.com',  '05301110012', 'hash12', 'Konya, Meram',           0, 1),
(1, 'Burak',   'Aydın',    'burak.aydin@mail.com',    '05301110013', 'hash13', 'Konya, Karatay',         0, 1),
(1, 'Gizem',   'Çınar',    'gizem.cinar@mail.com',    '05301110014', 'hash14', 'Bursa, Nilüfer',         1, 1),  -- ihtiyaç sahibi
(1, 'Enes',    'Karaca',   'enes.karaca@mail.com',    '05301110015', 'hash15', 'Bursa, Osmangazi',       0, 1),
(1, 'Buse',    'Güneş',    'buse.gunes@mail.com',     '05301110016', 'hash16', 'Antalya, Muratpaşa',     0, 1),
(1, 'Tarık',   'Bulut',    'tarik.bulut@mail.com',    '05301110017', 'hash17', 'Antalya, Kepez',         0, 1),
(1, 'Dilan',   'Aktaş',    'dilan.aktas@mail.com',    '05301110018', 'hash18', 'Gaziantep, Şahinbey',    1, 1),  -- ihtiyaç sahibi
(1, 'Sercan',  'Demirci',  'sercan.demirci@mail.com', '05301110019', 'hash19', 'Gaziantep, Şehitkamil',  0, 1),
(1, 'Özlem',   'Yıldız',   'ozlem.yildiz@mail.com',   '05301110020', 'hash20', 'Kayseri, Melikgazi',     0, 1),
-- Kuryeler (RolID=2)
(2, 'Ali',     'Kurtaran', 'ali.kurtaran@mail.com',   '05301119001', 'hashK1', 'Konya',                  0, 1),
(2, 'Veli',    'Hızlı',    'veli.hizli@mail.com',     '05301119002', 'hashK2', 'Konya',                  0, 1),
(2, 'Hüseyin', 'Çevik',    'huseyin.cevik@mail.com',  '05301119003', 'hashK3', 'Konya',                  0, 1),
-- Admin
(3, 'Platform','Admin',    'admin@yemeksiparis.com',  '05301119999', 'hashA1', 'Konya',                  0, 1);
GO

-- 5.3 Kuryeler
INSERT INTO Kuryeler (KullaniciID, PlakaNo, ToplamTeslimat) VALUES
    (21, '42 ABC 001', 120),
    (22, '42 DEF 002', 85),
    (23, '42 GHI 003', 60);
GO

-- 5.4 Restoranlar (5 restoran)
INSERT INTO Restoranlar (RestoranAdi, Adres, Telefon, Eposta, Puan, AcilisTarihi) VALUES
    ('Konya Döner Evi',        'Selçuklu, Konya',          '03321110001', 'iletisim@konyadorener.com', 0, '2020-03-15'),
    ('Lezzet Burger',          'Meram, Konya',             '03321110002', 'info@lezzetburger.com',     0, '2021-06-01'),
    ('Pizza Palazzo',          'Karatay, Konya',           '03321110003', 'siparis@pizzapalazzo.com',  0, '2019-11-20'),
    ('Deniz Balık Restaurant', 'Nilüfer, Bursa',           '02241110001', 'info@denizbalik.com',       0, '2018-05-10'),
    ('Taze Meyve Suları',      'Çankaya, Ankara',          '03121110001', 'hello@tazemeyve.com',       0, '2022-01-08');
GO

-- 5.5 Kategoriler
INSERT INTO Kategoriler (KategoriAdi) VALUES
    ('Döner'), ('Burger'), ('Pizza'), ('Balık'), ('İçecek'),
    ('Tatlı'), ('Salata'), ('Çorba'), ('Pilav'), ('Makarna');
GO

-- 5.6 Menü Ürünleri (50+ ürün)
-- Konya Döner Evi (RestoranID=1)
INSERT INTO MenuUrunleri (RestoranID, KategoriID, UrunAdi, Aciklama, Fiyat) VALUES
(1, 1, 'Kuzu Dürüm',        'Kuzu eti, lavaş, sebze',        85.00),
(1, 1, 'Tavuk Dürüm',       'Tavuk, lavaş, sos',             75.00),
(1, 1, 'Karışık Tabak',     'Kuzu+tavuk, pilav, salata',    130.00),
(1, 7, 'Mevsim Salata',     'Taze sebzeler',                  40.00),
(1, 8, 'Mercimek Çorbası',  'Ev yapımı',                      35.00),
(1, 9, 'Bulgur Pilavı',     'Tereyağlı bulgur',               30.00),
(1, 5, 'Ayran',             '500ml',                          15.00),
(1, 5, 'Kola',              'Kutu',                           20.00),
(1, 6, 'Künefe',            'Antep fıstıklı',                 65.00),
(1, 6, 'Baklava',           '4 dilim',                        55.00);

-- Lezzet Burger (RestoranID=2)
INSERT INTO MenuUrunleri (RestoranID, KategoriID, UrunAdi, Aciklama, Fiyat) VALUES
(2, 2, 'Klasik Burger',     '150gr dana, marul, domates',    95.00),
(2, 2, 'Çift Katmerli',     '2x150gr, özel sos',            135.00),
(2, 2, 'Tavuk Burger',      'Crispy tavuk, coleslaw',         90.00),
(2, 2, 'Mantar Burger',     'Portobello, vegan sos',          85.00),
(2, 7, 'Coleslaw',          'Kremalı lahana salatası',        30.00),
(2, 5, 'Milkshake',         'Çikolata/Vanilyalı',            45.00),
(2, 5, 'Limonata',          'Taze sıkılmış',                  30.00),
(2, 6, 'Brownie',           'Sıcak, dondurma ile',            55.00),
(2, 2, 'Vejetaryen Burger', 'Nohut köfteli',                  80.00),
(2, 2, 'Kaşarlı Burger',    'Ekstra kaşar peyniri',           100.00);

-- Pizza Palazzo (RestoranID=3)
INSERT INTO MenuUrunleri (RestoranID, KategoriID, UrunAdi, Aciklama, Fiyat) VALUES
(3, 3, 'Margherita',        'Domates, mozzarella, fesleğen', 120.00),
(3, 3, 'Karışık Pizza',     'Sucuk, mantar, biber',          145.00),
(3, 3, 'BBQ Tavuk',         'Barbekü sos, ızgara tavuk',     140.00),
(3, 3, 'Prosciutto',        'Pastırma, roka, parmesan',      155.00),
(3, 3, '4 Cheese',          '4 çeşit peynir',                150.00),
(3, 10,'Spaghetti Bolognese','Dana kıyma, domates sos',       95.00),
(3, 10,'Fettuccine Carbonara','Pancetta, yumurta, parmesan', 105.00),
(3, 7, 'Sezar Salata',      'Romaine, parmesan, kruton',      60.00),
(3, 5, 'Cappuccino',        'Espresso, köpüklü süt',          35.00),
(3, 6, 'Tiramisu',          'Mascarpone, Ladyfinger',         65.00);

-- Deniz Balık Restaurant (RestoranID=4)
INSERT INTO MenuUrunleri (RestoranID, KategoriID, UrunAdi, Aciklama, Fiyat) VALUES
(4, 4, 'Levrek Izgara',     '400gr taze levrek',             220.00),
(4, 4, 'Çipura Fırın',      'Sebzeli, limonlu',              210.00),
(4, 4, 'Karidesli Güveç',   'Karides, domates sos',          185.00),
(4, 4, 'Balık Sandviç',     'Ekmek arası lüfer',             120.00),
(4, 8, 'Balık Çorbası',     'Ev yapımı',                      55.00),
(4, 7, 'Deniz Mahsülleri Salatası','Ahtapot, karides',       90.00),
(4, 5, 'Rakı',              '35cl',                          150.00),
(4, 5, 'Beyaz Şarap',       'Bardak',                         60.00),
(4, 6, 'Muhallebi',         'Fıstıklı',                       45.00),
(4, 9, 'Pilav',             'Tereyağlı',                      30.00);

-- Taze Meyve Suları (RestoranID=5)
INSERT INTO MenuUrunleri (RestoranID, KategoriID, UrunAdi, Aciklama, Fiyat) VALUES
(5, 5, 'Portakal Suyu',     '500ml taze sıkılmış',            35.00),
(5, 5, 'Nar Suyu',          '400ml',                          40.00),
(5, 5, 'Smoothie',          'Muz-çilek karışım',              45.00),
(5, 5, 'Detox Karışımı',    'Elma-zencefil-limon',            50.00),
(5, 5, 'Şeftali Suyu',      '500ml',                          35.00),
(5, 6, 'Meyve Tabağı',      'Mevsim meyveleri',               55.00),
(5, 6, 'Açma',              'Taze fırın',                     20.00),
(5, 6, 'Simit',             'Susam kaplı',                    15.00),
(5, 7, 'Meyve Salatası',    'Mevsim meyveleri, limon',        45.00),
(5, 5, 'Limonata',          'Taze limon, nane',               30.00);
GO

-- Bir ürünü soft delete ile pasife çek (test amaçlı)
UPDATE MenuUrunleri SET IsActive = 0 WHERE UrunID = 37; -- Rakı kaldırıldı
GO

-- 5.7 Askıda Yemek Bağışları
INSERT INTO AskidaYemekHavuzu (BagisciID, BagisTutari, BagisAciklama, BagisTarihi) VALUES
(1,  150.00, 'Hayırlı olsun',           '2024-12-01 10:00:00'),
(3,  200.00, NULL,                       '2024-12-05 14:30:00'), -- anonim hissedebilir ama bilgi var
(5,  100.00, 'Bir öğün karşılayabilir', '2024-12-10 09:00:00'),
(7,  250.00, 'İyi kullanın',            '2024-12-15 18:00:00'),
(9,   75.00, NULL,                       '2025-01-02 11:00:00'),
(11, 300.00, 'Allah kabul etsin',       '2025-01-10 20:00:00'),
(13, 120.00, NULL,                       '2025-01-20 16:00:00'),
(15,  80.00, 'Bir aile için',           '2025-02-01 08:00:00'),
(NULL,500.00,'Anonim bağış',            '2025-02-10 12:00:00'), -- tamamen anonim
(17, 200.00, 'Hayırlı olsun',           '2025-02-15 10:00:00');
GO

-- 5.8 Siparişler (100 sipariş - normal + askıda yemek)
-- İlk 95 normal sipariş
INSERT INTO Siparisler (KullaniciID, RestoranID, SiparisTarihi, ToplamTutar, Durum, AskidaYemekKullanildi) VALUES
(1, 1,  '2024-12-01 12:00', 185.00, 'TeslimEdildi', 0),
(1, 2,  '2024-12-03 19:00', 95.00,  'TeslimEdildi', 0),
(3, 3,  '2024-12-04 13:00', 265.00, 'TeslimEdildi', 0),
(3, 1,  '2024-12-05 20:00', 130.00, 'TeslimEdildi', 0),
(5, 2,  '2024-12-06 12:30', 225.00, 'TeslimEdildi', 0),
(5, 3,  '2024-12-07 19:30', 145.00, 'TeslimEdildi', 0),
(6, 4,  '2024-12-08 14:00', 430.00, 'TeslimEdildi', 0),
(7, 5,  '2024-12-09 10:00', 80.00,  'TeslimEdildi', 0),
(9, 1,  '2024-12-10 21:00', 215.00, 'TeslimEdildi', 0),
(9, 2,  '2024-12-11 12:00', 190.00, 'TeslimEdildi', 0),
(10,3,  '2024-12-12 18:30', 270.00, 'TeslimEdildi', 0),
(10,4,  '2024-12-13 20:00', 405.00, 'TeslimEdildi', 0),
(11,1,  '2024-12-14 13:00', 130.00, 'TeslimEdildi', 0),
(11,5,  '2024-12-15 09:30', 110.00, 'TeslimEdildi', 0),
(12,2,  '2024-12-16 19:00', 135.00, 'TeslimEdildi', 0),
(12,3,  '2024-12-17 12:30', 150.00, 'TeslimEdildi', 0),
(13,4,  '2024-12-18 21:00', 430.00, 'TeslimEdildi', 0),
(13,1,  '2024-12-19 20:00', 85.00,  'TeslimEdildi', 0),
(15,2,  '2024-12-20 12:00', 95.00,  'TeslimEdildi', 0),
(15,3,  '2024-12-21 18:30', 265.00, 'TeslimEdildi', 0),
(16,5,  '2024-12-22 10:00', 70.00,  'TeslimEdildi', 0),
(16,1,  '2024-12-23 19:30', 195.00, 'TeslimEdildi', 0),
(17,2,  '2024-12-24 13:00', 225.00, 'TeslimEdildi', 0),
(17,4,  '2024-12-25 20:30', 440.00, 'TeslimEdildi', 0),
(19,3,  '2024-12-26 12:00', 120.00, 'TeslimEdildi', 0),
(19,5,  '2024-12-27 09:00', 115.00, 'TeslimEdildi', 0),
(20,1,  '2024-12-28 19:00', 130.00, 'TeslimEdildi', 0),
(20,2,  '2024-12-29 12:30', 270.00, 'TeslimEdildi', 0),
(1, 3,  '2024-12-30 20:00', 265.00, 'TeslimEdildi', 0),
(3, 4,  '2024-12-31 18:00', 430.00, 'TeslimEdildi', 0),
-- Ocak 2025
(5, 1,  '2025-01-02 12:00', 215.00, 'TeslimEdildi', 0),
(6, 2,  '2025-01-03 19:00', 95.00,  'TeslimEdildi', 0),
(7, 3,  '2025-01-04 13:00', 275.00, 'TeslimEdildi', 0),
(9, 5,  '2025-01-05 10:30', 80.00,  'TeslimEdildi', 0),
(10,1,  '2025-01-06 20:00', 130.00, 'TeslimEdildi', 0),
(11,2,  '2025-01-07 12:00', 190.00, 'TeslimEdildi', 0),
(12,4,  '2025-01-08 18:00', 395.00, 'TeslimEdildi', 0),
(13,3,  '2025-01-09 21:00', 145.00, 'TeslimEdildi', 0),
(15,1,  '2025-01-10 13:00', 170.00, 'TeslimEdildi', 0),
(16,2,  '2025-01-11 19:30', 225.00, 'TeslimEdildi', 0),
(17,5,  '2025-01-12 10:00', 65.00,  'TeslimEdildi', 0),
(19,3,  '2025-01-13 20:00', 120.00, 'TeslimEdildi', 0),
(20,4,  '2025-01-14 14:00', 485.00, 'TeslimEdildi', 0),
(1, 2,  '2025-01-15 12:30', 135.00, 'TeslimEdildi', 0),
(3, 5,  '2025-01-16 19:00', 115.00, 'TeslimEdildi', 0),
(5, 1,  '2025-01-17 13:30', 215.00, 'TeslimEdildi', 0),
(6, 3,  '2025-01-18 20:30', 295.00, 'TeslimEdildi', 0),
(7, 4,  '2025-01-19 18:00', 430.00, 'TeslimEdildi', 0),
(9, 2,  '2025-01-20 12:00', 100.00, 'TeslimEdildi', 0),
(10,1,  '2025-01-21 19:30', 85.00,  'TeslimEdildi', 0),
-- Şubat 2025
(11,3,  '2025-02-01 12:00', 265.00, 'TeslimEdildi', 0),
(12,2,  '2025-02-02 19:00', 95.00,  'TeslimEdildi', 0),
(13,4,  '2025-02-03 14:00', 405.00, 'TeslimEdildi', 0),
(15,5,  '2025-02-04 10:00', 115.00, 'TeslimEdildi', 0),
(16,1,  '2025-02-05 20:00', 130.00, 'TeslimEdildi', 0),
(17,3,  '2025-02-06 12:30', 145.00, 'TeslimEdildi', 0),
(19,2,  '2025-02-07 19:30', 190.00, 'TeslimEdildi', 0),
(20,4,  '2025-02-08 18:00', 430.00, 'TeslimEdildi', 0),
(1, 5,  '2025-02-09 09:00', 70.00,  'TeslimEdildi', 0),
(3, 1,  '2025-02-10 20:00', 215.00, 'TeslimEdildi', 0),
(5, 2,  '2025-02-11 12:30', 225.00, 'TeslimEdildi', 0),
(6, 3,  '2025-02-12 19:00', 150.00, 'TeslimEdildi', 0),
(7, 1,  '2025-02-13 13:00', 170.00, 'TeslimEdildi', 0),
(9, 4,  '2025-02-14 20:30', 430.00, 'TeslimEdildi', 0),
(10,2,  '2025-02-15 12:00', 95.00,  'TeslimEdildi', 0),
(11,5,  '2025-02-16 19:00', 80.00,  'TeslimEdildi', 0),
(12,1,  '2025-02-17 13:30', 215.00, 'TeslimEdildi', 0),
(13,2,  '2025-02-18 20:00', 135.00, 'TeslimEdildi', 0),
(15,3,  '2025-02-19 12:00', 270.00, 'TeslimEdildi', 0),
(16,4,  '2025-02-20 18:00', 410.00, 'TeslimEdildi', 0),
(17,1,  '2025-02-21 20:30', 85.00,  'TeslimEdildi', 0),
(19,5,  '2025-02-22 10:00', 115.00, 'TeslimEdildi', 0),
(20,2,  '2025-02-23 19:00', 190.00, 'TeslimEdildi', 0),
(1, 3,  '2025-03-01 12:30', 265.00, 'TeslimEdildi', 0),
(3, 4,  '2025-03-02 19:00', 220.00, 'TeslimEdildi', 0),
(5, 5,  '2025-03-03 10:00', 80.00,  'TeslimEdildi', 0),
(6, 1,  '2025-03-04 20:00', 130.00, 'TeslimEdildi', 0),
(7, 2,  '2025-03-05 12:00', 100.00, 'TeslimEdildi', 0),
(9, 3,  '2025-03-06 18:30', 145.00, 'TeslimEdildi', 0),
(10,4,  '2025-03-07 21:00', 430.00, 'TeslimEdildi', 0),
(11,5,  '2025-03-08 09:30', 115.00, 'TeslimEdildi', 0),
(12,1,  '2025-03-09 13:00', 215.00, 'TeslimEdildi', 0),
(13,2,  '2025-03-10 19:30', 270.00, 'TeslimEdildi', 0),
(15,3,  '2025-03-11 12:00', 150.00, 'TeslimEdildi', 0),
(16,4,  '2025-03-12 20:00', 390.00, 'TeslimEdildi', 0),
(17,5,  '2025-03-13 10:30', 65.00,  'TeslimEdildi', 0),
(19,1,  '2025-03-14 19:00', 130.00, 'TeslimEdildi', 0),
(20,2,  '2025-03-15 12:30', 95.00,  'TeslimEdildi', 0),
(1, 4,  '2025-03-20 19:00', 430.00, 'TeslimEdildi', 0),
(3, 2,  '2025-03-21 12:00', 225.00, 'TeslimEdildi', 0),
(5, 3,  '2025-03-22 20:00', 265.00, 'TeslimEdildi', 0),
-- Aktif/Beklemedeki siparişler
(6, 1,  '2025-05-20 12:00', 130.00, 'Hazırlanıyor', 0),
(7, 2,  '2025-05-20 13:00', 95.00,  'Yolda',        0),
(9, 3,  '2025-05-21 19:00', 265.00, 'Beklemede',    0),
(10,4,  '2025-05-21 20:00', 430.00, 'Beklemede',    0);
GO

-- 5.9 Askıda Yemek ile verilen siparişler (ihtiyaç sahipleri)
-- KullaniciID: 2, 4, 8, 14, 18 (IhtiyacDogrulamasi=1 olanlar)
INSERT INTO Siparisler (KullaniciID, RestoranID, SiparisTarihi, ToplamTutar, Durum, AskidaYemekKullanildi) VALUES
(2,  1, '2025-01-15 12:00', 130.00, 'TeslimEdildi', 1),
(4,  2, '2025-02-01 19:00', 95.00,  'TeslimEdildi', 1),
(8,  1, '2025-02-20 12:00', 85.00,  'TeslimEdildi', 1),
(14, 3, '2025-03-05 13:00', 120.00, 'TeslimEdildi', 1),
(18, 2, '2025-03-18 19:00', 95.00,  'TeslimEdildi', 1);
GO

-- 5.10 Sipariş Detayları (bazı siparişler için)
INSERT INTO SiparisDetaylari (SiparisID, UrunID, Adet, BirimFiyat) VALUES
-- Sipariş 1 (KullaniciID=1, Restoran=KonyaDöner)
(1, 1, 1, 85.00),  -- Kuzu Dürüm
(1, 7, 2, 15.00),  -- Ayran x2
(1, 9, 1, 65.00),  -- Künefe
-- Sipariş 2 (KullaniciID=1, Restoran=LezzetBurger)
(2, 11, 1, 95.00), -- Klasik Burger
-- Sipariş 3 (KullaniciID=3, Restoran=PizzaPalazzo)
(3, 21, 1, 120.00),-- Margherita
(3, 26, 1, 95.00), -- Spaghetti
(3, 28, 1, 60.00), -- Sezar Salata
-- Sipariş 96 (Askıda Yemek, KullaniciID=2)
(96, 3, 1, 130.00);-- Karışık Tabak
GO

-- 5.11 Sipariş-Kurye Atamaları
INSERT INTO SiparisKuryeAtama (SiparisID, KuryeID, AtamaTarihi, TeslimTarihi) VALUES
(1,  1, '2024-12-01 12:10', '2024-12-01 12:45'),
(2,  2, '2024-12-03 19:10', '2024-12-03 19:50'),
(3,  1, '2024-12-04 13:15', '2024-12-04 14:00'),
(4,  3, '2024-12-05 20:05', '2024-12-05 20:40'),
(5,  2, '2024-12-06 12:35', '2024-12-06 13:10');
GO

-- 5.12 Değerlendirmeler
INSERT INTO Degerlendirmeler (SiparisID, KullaniciID, RestoranID, Puan, Yorum) VALUES
(1,  1,  1, 5, 'Muhteşem döner, çok lezzetliydi!'),
(2,  1,  2, 4, 'Burger güzeldi, biraz geç geldi.'),
(3,  3,  3, 5, 'Pizza mükemmeldi.'),
(5,  5,  2, 4, 'Lezzetli ama paket biraz ezilmişti.'),
(7,  6,  4, 5, 'Levrek çok tazeydi, harika!'),
(9,  9,  1, 4, 'İyi döner, tavsiye ederim.'),
(11, 10, 3, 3, 'Pizza soğuk geldi.'),
(13, 11, 1, 5, 'Her zamanki gibi nefis.'),
(15, 12, 2, 4, 'Güzeldi.'),
(17, 13, 4, 5, 'Balık restoranı çok iyiymiş, tekrar geleceğim.');
GO

-- ============================================================
-- 6. İLERİ DÜZEY SORGULAR
-- ============================================================

-- ---------------------------------------------------------------
-- 6.1 JOIN: En Az 3 Tabloyu Birleştiren Sipariş Fişi Sorgusu
--     Bir siparişin tam detayını (müşteri, restoran, ürünler) getirir
-- ---------------------------------------------------------------
-- Bu sorgu: Siparisler + Kullanicilar + Restoranlar + SiparisDetaylari + MenuUrunleri
SELECT
    s.SiparisID,
    s.SiparisTarihi,
    k.Ad + ' ' + k.Soyad           AS MusteriAdi,
    k.Eposta                        AS MusteriEposta,
    r.RestoranAdi,
    m.UrunAdi,
    sd.Adet,
    sd.BirimFiyat,
    sd.Adet * sd.BirimFiyat         AS SatirToplami,
    s.ToplamTutar                   AS SiparisGenelToplam,
    s.Durum,
    CASE WHEN s.AskidaYemekKullanildi = 1 THEN 'Evet' ELSE 'Hayır' END AS AskidaYemekMi
FROM Siparisler s
INNER JOIN Kullanicilar    k  ON s.KullaniciID = k.KullaniciID
INNER JOIN Restoranlar     r  ON s.RestoranID  = r.RestoranID
INNER JOIN SiparisDetaylari sd ON s.SiparisID  = sd.SiparisID
INNER JOIN MenuUrunleri    m  ON sd.UrunID     = m.UrunID
WHERE s.IsActive = 1
ORDER BY s.SiparisID, m.UrunAdi;
GO

-- ---------------------------------------------------------------
-- 6.2 Agregasyon: Son 1 Ayda 5'ten Fazla Sipariş Alan Restoranların
--     Ortalama Sepet Tutarları (GROUP BY + HAVING + AVG + SUM + COUNT)
-- ---------------------------------------------------------------
SELECT
    r.RestoranID,
    r.RestoranAdi,
    COUNT(s.SiparisID)          AS SiparisSayisi,
    SUM(s.ToplamTutar)          AS ToplamCiro,
    AVG(s.ToplamTutar)          AS OrtalamaSebet,
    MAX(s.ToplamTutar)          AS EnBuyukSiparis,
    MIN(s.ToplamTutar)          AS EnKucukSiparis
FROM Siparisler s
INNER JOIN Restoranlar r ON s.RestoranID = r.RestoranID
WHERE s.SiparisTarihi >= DATEADD(MONTH, -1, GETDATE())
  AND s.IsActive = 1
GROUP BY r.RestoranID, r.RestoranAdi
HAVING COUNT(s.SiparisID) > 5
ORDER BY SiparisSayisi DESC;
GO

-- ---------------------------------------------------------------
-- 6.3 Alt Sorgu (Subquery + NOT EXISTS):
--     Hiç "Askıda Yemek" bağışı yapmamış ama platformu aktif kullanan müşteriler
-- ---------------------------------------------------------------
SELECT
    k.KullaniciID,
    k.Ad + ' ' + k.Soyad AS MusteriAdi,
    k.Eposta,
    COUNT(s.SiparisID)    AS ToplamSiparis
FROM Kullanicilar k
INNER JOIN Siparisler s ON k.KullaniciID = s.KullaniciID
WHERE k.IsActive = 1
  AND k.RolID = 1  -- Sadece müşteriler
  AND NOT EXISTS (
        SELECT 1
        FROM AskidaYemekHavuzu ayh
        WHERE ayh.BagisciID = k.KullaniciID
  )
GROUP BY k.KullaniciID, k.Ad, k.Soyad, k.Eposta
HAVING COUNT(s.SiparisID) >= 3
ORDER BY ToplamSiparis DESC;
GO

-- ---------------------------------------------------------------
-- 6.4 Alt Sorgu (IN):
--     Askıda Yemek Havuzundan Son 1 Haftada Yararlanan Kullanıcılar
-- ---------------------------------------------------------------
SELECT
    k.KullaniciID,
    k.Ad + ' ' + k.Soyad  AS MusteriAdi,
    k.Eposta,
    s.SiparisTarihi,
    s.ToplamTutar
FROM Kullanicilar k
INNER JOIN Siparisler s ON k.KullaniciID = s.KullaniciID
WHERE s.AskidaYemekKullanildi = 1
  AND s.SiparisTarihi >= DATEADD(WEEK, -1, GETDATE())
  AND s.SiparisID IN (
        SELECT KullananSiparisID
        FROM AskidaYemekHavuzu
        WHERE KullanildiMi = 1
  )
ORDER BY s.SiparisTarihi DESC;
GO

-- ---------------------------------------------------------------
-- 6.5 EXISTS: Askıda Yemek Havuzunda Yeterli Bakiye Var mı? (kontrol sorgusu)
-- ---------------------------------------------------------------
SELECT
    CASE WHEN EXISTS (
        SELECT 1
        FROM AskidaYemekHavuzu
        WHERE KullanildiMi = 0
          AND BagisTutari >= 75  -- en az 75 TL bakiye olan bağış var mı?
    )
    THEN 'Havuzda yeterli bakiye mevcut.'
    ELSE 'Havuz yetersiz, bağışa ihtiyaç var.'
    END AS HavuzDurumu;
GO

-- ---------------------------------------------------------------
-- 6.6 VIEW Kullanımı: Askıda Yemek Havuz Durumu
-- ---------------------------------------------------------------
SELECT * FROM vw_AskidaYemekHavuzDurumu;
GO

-- ---------------------------------------------------------------
-- 6.7 VIEW Kullanımı: Aktif Restoran Menüleri
-- ---------------------------------------------------------------
SELECT * FROM vw_AktifRestoranMenuleri
ORDER BY RestoranAdi, KategoriAdi, UrunAdi;
GO

-- ---------------------------------------------------------------
-- 6.8 VIEW Kullanımı: Teslim Edilen Siparişler
-- ---------------------------------------------------------------
SELECT * FROM vw_TeslimEdilmisSiparisler
ORDER BY SiparisTarihi DESC;
GO

-- ============================================================
-- 7. İŞ KURALLARI ÖZET / KONTROL SORGULARI
-- ============================================================

-- Restoran ciro durumu (Trigger sonrası güncellendi mi?)
SELECT RestoranID, RestoranAdi, ToplamCiro, Puan FROM Restoranlar;
GO

-- Havuz bakiyesi dağılımı
SELECT
    BagisciID,
    CASE WHEN BagisciID IS NULL THEN 'Anonim' ELSE CAST(BagisciID AS NVARCHAR) END AS Bagisci,
    BagisTutari,
    BagisTarihi,
    CASE WHEN KullanildiMi = 1 THEN 'Kullanıldı' ELSE 'Kullanılabilir' END AS Durum
FROM AskidaYemekHavuzu
ORDER BY BagisTarihi;
GO

-- İhtiyaç sahibi kullanıcıların sipariş geçmişi
SELECT
    k.Ad + ' ' + k.Soyad AS MusteriAdi,
    s.SiparisTarihi,
    r.RestoranAdi,
    s.ToplamTutar,
    CASE WHEN s.AskidaYemekKullanildi = 1 THEN 'Askıda Yemek' ELSE 'Normal' END AS OdemeTipi
FROM Kullanicilar k
INNER JOIN Siparisler  s ON k.KullaniciID = s.KullaniciID
INNER JOIN Restoranlar r ON s.RestoranID  = r.RestoranID
WHERE k.IhtiyacDogrulamasi = 1
ORDER BY k.KullaniciID, s.SiparisTarihi;
GO

-- ============================================================
-- 8. YAPAY ZEKA KULLANIM BEYANI
-- ============================================================
/*
Bu projede Claude (Anthropic) yapay zeka aracından aşağıdaki aşamalarda yararlanılmıştır:
- Schema tasarımı ve normalizasyon kontrolü (3NF uygunluğu),
- Trigger ve View yazımında sözdizimi doğrulama,
- Test verileri (mock data) üretimi,
- CHECK, FK, UNIQUE kısıtlamalarının gözden geçirilmesi.

Projenin tüm mantığı, iş kuralları ve "Askıda Yemek" modülünün çalışma biçimi
öğrenci tarafından anlaşılmış ve tasarlanmıştır. AI yalnızca geliştirme aşamasında
asistan olarak kullanılmıştır.
*/
GO