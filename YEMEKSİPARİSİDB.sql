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