-- Veritabanı Oluşturma
CREATE DATABASE IF NOT EXISTS inventory_system;
USE inventory_system;

-- 1. Kategoriler Tablosu
CREATE TABLE categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    parent_id INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_id) REFERENCES categories(category_id) ON DELETE SET NULL
);

-- 2. Markalar Tablosu
CREATE TABLE brands (
    brand_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 3. İzinler Tablosu
CREATE TABLE permissions (
    permission_id INT AUTO_INCREMENT PRIMARY KEY,
    permission_name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT
);

-- 4. Roller Tablosu
CREATE TABLE role (
    role_id INT AUTO_INCREMENT PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL UNIQUE,
    role_description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    is_delete BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 5. Rol-İzin İlişki Tablosu
CREATE TABLE role_permissions (
    role_id INT NOT NULL,
    permission_id INT NOT NULL,
    PRIMARY KEY (role_id, permission_id),
    FOREIGN KEY (role_id) REFERENCES role(role_id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(permission_id) ON DELETE CASCADE
);

-- 6. Kullanıcılar Tablosu
CREATE TABLE user (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    usermail VARCHAR(255) NOT NULL UNIQUE,
    userpassword VARCHAR(255) NOT NULL CHECK (CHAR_LENGTH(userpassword) >= 8),
    user_fullname VARCHAR(100) NOT NULL,
    user_phone VARCHAR(15) NOT NULL,
    user_address TEXT,
    user_roleid INT DEFAULT 1 NOT NULL,
    last_login TIMESTAMP NULL,
    is_active BOOLEAN DEFAULT TRUE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_roleid) REFERENCES role(role_id)
);

-- 7. Ürünler Tablosu
CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    sku VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    category_id INT,
    brand_id INT,
    unit_price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    reorder_level INT NOT NULL DEFAULT 5,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE SET NULL,
    FOREIGN KEY (brand_id) REFERENCES brands(brand_id) ON DELETE SET NULL
);

-- 8. Depolar Tablosu
CREATE TABLE warehouses (
    warehouse_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    location VARCHAR(200) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 9. Stok Seviyeleri Tablosu
CREATE TABLE stock_levels (
    product_id INT NOT NULL,
    warehouse_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (product_id, warehouse_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id)
);

-- 10. Stok Hareketleri
CREATE TABLE stock_movements (
    movement_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    warehouse_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    movement_type ENUM('purchase', 'sale', 'return', 'adjustment', 'transfer_in', 'transfer_out') NOT NULL,
    movement_status ENUM('pending', 'completed', 'cancelled') NOT NULL DEFAULT 'completed',
    movement_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reference_id VARCHAR(100),
    notes TEXT,
    created_by INT NOT NULL,
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id),
    FOREIGN KEY (created_by) REFERENCES user(user_id)
);

-- 11. Transfer Tablosu
CREATE TABLE stock_transfers (
    transfer_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    from_warehouse_id INT NOT NULL,
    to_warehouse_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    transfer_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    transfer_status ENUM('pending', 'in_transit', 'completed', 'cancelled') NOT NULL DEFAULT 'pending',
    reference_id VARCHAR(100),
    notes TEXT,
    created_by INT NOT NULL,
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (from_warehouse_id) REFERENCES warehouses(warehouse_id),
    FOREIGN KEY (to_warehouse_id) REFERENCES warehouses(warehouse_id),
    FOREIGN KEY (created_by) REFERENCES user(user_id)
);

-- 12. Denetim Günlüğü Tablosu
CREATE TABLE audit_log (
    audit_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    action_type VARCHAR(50) NOT NULL,
    table_name VARCHAR(50) NOT NULL,
    record_id INT NOT NULL,
    action_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    old_values JSON,
    new_values JSON,
    FOREIGN KEY (user_id) REFERENCES user(user_id)
);

-- 13. Stok Yetersizliğini Önleyici Trigger
DELIMITER $$
CREATE TRIGGER check_stock_before_sale
BEFORE INSERT ON stock_movements
FOR EACH ROW
BEGIN
  IF NEW.movement_type IN ('sale', 'adjustment', 'transfer_out') THEN
    DECLARE current_qty INT;
    
    -- Get current stock from materialized view
    SELECT quantity INTO current_qty
    FROM stock_levels
    WHERE product_id = NEW.product_id AND warehouse_id = NEW.warehouse_id;
    
    IF current_qty < NEW.quantity THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stok yetersiz!';
    END IF;
  END IF;
END$$
DELIMITER ;

-- 14. Stok Seviyelerini Güncelleyen Trigger
DELIMITER $$
CREATE TRIGGER update_stock_levels
AFTER INSERT ON stock_movements
FOR EACH ROW
BEGIN
  -- Update materialized stock view
  INSERT INTO stock_levels (product_id, warehouse_id, quantity)
  VALUES (NEW.product_id, NEW.warehouse_id, NEW.quantity)
  ON DUPLICATE KEY UPDATE 
      quantity = quantity + 
        CASE 
          WHEN NEW.movement_type IN ('purchase', 'return', 'transfer_in') THEN NEW.quantity
          WHEN NEW.movement_type IN ('sale', 'adjustment', 'transfer_out') THEN -NEW.quantity
          ELSE 0
        END;
END$$
DELIMITER ;

-- 15. Transfer İşlemlerini Otomatikleştiren Trigger
DELIMITER $$
CREATE TRIGGER process_stock_transfer
AFTER INSERT ON stock_transfers
FOR EACH ROW
BEGIN
  -- Only process if transfer is pending
  IF NEW.transfer_status = 'pending' THEN
    -- Deduct from source warehouse
    INSERT INTO stock_movements (
        product_id, warehouse_id, quantity, 
        movement_type, reference_id, created_by
    ) VALUES (
        NEW.product_id, NEW.from_warehouse_id, NEW.quantity,
        'transfer_out', CONCAT('TR-', NEW.transfer_id), NEW.created_by
    );
    
    -- Add to destination warehouse
    INSERT INTO stock_movements (
        product_id, warehouse_id, quantity, 
        movement_type, reference_id, created_by
    ) VALUES (
        NEW.product_id, NEW.to_warehouse_id, NEW.quantity,
        'transfer_in', CONCAT('TR-', NEW.transfer_id), NEW.created_by
    );
    
    -- Update transfer status
    UPDATE stock_transfers SET transfer_status = 'completed' WHERE transfer_id = NEW.transfer_id;
  END IF;
END$$
DELIMITER ;

-- 16. Şifre Politikasını Zorlayan Trigger
DELIMITER $$
CREATE TRIGGER enforce_password_policy
BEFORE INSERT ON user
FOR EACH ROW
BEGIN
  IF CHAR_LENGTH(NEW.userpassword) < 8 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Parola en az 8 karakter uzunluğunda olmalıdır';
  END IF;
END$$
DELIMITER ;

-- 17. Stok Görünümü (Materialized view yerine transactional view)
CREATE VIEW current_stock AS
SELECT 
    p.product_id,
    p.sku,
    p.name AS product_name,
    w.warehouse_id,
    w.name AS warehouse_name,
    sl.quantity AS current_quantity,
    p.reorder_level,
    CASE WHEN sl.quantity <= p.reorder_level THEN 'LOW' ELSE 'OK' END AS stock_status
FROM stock_levels sl
JOIN products p ON sl.product_id = p.product_id
JOIN warehouses w ON sl.warehouse_id = w.warehouse_id;

-- 18. Kullanıcı İzinleri Görünümü
CREATE VIEW user_permissions AS
SELECT 
    u.user_id,
    u.usermail,
    r.role_name,
    GROUP_CONCAT(p.permission_name SEPARATOR ', ') AS permissions
FROM user u
JOIN role r ON u.user_roleid = r.role_id
JOIN role_permissions rp ON r.role_id = rp.role_id
JOIN permissions p ON rp.permission_id = p.permission_id
GROUP BY u.user_id, u.usermail, r.role_name;

-- 19. Düşük Stok Uyarı Görünümü
CREATE VIEW low_stock_alerts AS
SELECT 
    s.product_id,
    s.product_name,
    s.warehouse_id,
    s.warehouse_name,
    s.current_quantity,
    s.reorder_level,
    p.unit_price
FROM current_stock s
JOIN products p ON s.product_id = p.product_id
WHERE s.current_quantity <= s.reorder_level;

-- 20. İndeksler
CREATE INDEX idx_user_role ON user(user_roleid);
CREATE INDEX idx_stock_product ON stock_movements(product_id);
CREATE INDEX idx_stock_warehouse ON stock_movements(warehouse_id);
CREATE INDEX idx_stock_created_by ON stock_movements(created_by);
CREATE INDEX idx_stock_movement_date ON stock_movements(movement_date);
CREATE INDEX idx_products_sku ON products(sku);
CREATE INDEX idx_reference_id ON stock_movements(reference_id);
CREATE INDEX idx_movement_type ON stock_movements(movement_type);
CREATE INDEX idx_transfer_status ON stock_transfers(transfer_status);
CREATE INDEX idx_product_price ON products(unit_price);
CREATE INDEX idx_category_name ON categories(name);
CREATE INDEX idx_brand_name ON brands(name);

-- 21. Örnek Veriler
-- Kategoriler
INSERT INTO categories (name, parent_id) VALUES
('Elektronik', NULL),
('Telefon', 1),
('Bilgisayar', 1),
('Yazılım', NULL);

-- Markalar
INSERT INTO brands (name) VALUES
('Apple'),
('Samsung'),
('HP'),
('Microsoft');

-- İzinler
INSERT INTO permissions (permission_name, description) VALUES
('stock_read', 'Stok bilgilerini görüntüleme'),
('stock_write', 'Yeni stok hareketi oluşturma'),
('stock_update', 'Stok hareketlerini güncelleme'),
('stock_delete', 'Stok hareketlerini silme'),
('user_manage', 'Kullanıcı yönetimi'),
('report_view', 'Raporları görüntüleme'),
('transfer_manage', 'Stok transferlerini yönetme');

-- Roller
INSERT INTO role (role_name, role_description) VALUES
('Sistem Yöneticisi', 'Tüm sistem üzerinde tam yetki'),
('Stok Yöneticisi', 'Stok hareketlerini yönetir'),
('Satış Temsilcisi', 'Satış işlemlerini yönetir'),
('Raporlama Uzmanı', 'Sadece raporları görüntüler'),
('Depo Sorumlusu', 'Depo transferlerini yönetir');

-- Rol-İzin İlişkileri
INSERT INTO role_permissions (role_id, permission_id) VALUES
(1, 1), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7),
(2, 1), (2, 2), (2, 3), (2, 6),
(3, 1), (3, 2), (3, 6),
(4, 1), (4, 6),
(5, 1), (5, 2), (5, 7), (5, 6);

-- Kullanıcılar
INSERT INTO user (usermail, userpassword, user_fullname, user_phone, user_address, user_roleid) VALUES
('admin@firma.com', '$2y$10$EXAMPLEHASHEDPASSWORDSECURE', 'Ahmet Yılmaz', '05551112233', 'İstanbul', 1),
('stok@firma.com', '$2y$10$EXAMPLEHASHEDPASSWORDSECURE', 'Mehmet Demir', '05552223344', 'Ankara', 2),
('satis@firma.com', '$2y$10$EXAMPLEHASHEDPASSWORDSECURE', 'Ayşe Kaya', '05553334455', 'İzmir', 3),
('rapor@firma.com', '$2y$10$EXAMPLEHASHEDPASSWORDSECURE', 'Fatma Şahin', '05554445566', 'Bursa', 4),
('depo@firma.com', '$2y$10$EXAMPLEHASHEDPASSWORDSECURE', 'Ali Veli', '05556667788', 'Adana', 5);

-- Ürünler
INSERT INTO products (name, sku, description, category_id, brand_id, unit_price, reorder_level) VALUES
('iPhone 13 Pro', 'IP13P-128-BLK', '128GB Siyah iPhone 13 Pro', 2, 1, 21999.99, 5),
('Samsung Galaxy S22', 'SGS22-256-BLUE', '256GB Mavi Samsung Galaxy S22', 2, 2, 18999.90, 8),
('HP Pavilion Laptop', 'HPPAV-15-2023', '15.6 inç i7 işlemci', 3, 3, 15999.00, 3);

-- Depolar
INSERT INTO warehouses (name, location) VALUES
('Merkez Depo', 'İstanbul, Maslak'),
('Anadolu Deposu', 'Ankara, Çankaya'),
('Ege Deposu', 'İzmir, Bornova');

-- Stok Hareketleri
INSERT INTO stock_movements (product_id, warehouse_id, quantity, unit_price, movement_type, reference_id, notes, created_by) VALUES
(1, 1, 50, 20000.00, 'purchase', 'PO-2023-001', 'İlk stok alımı', 1),
(2, 1, 30, 17000.00, 'purchase', 'PO-2023-002', 'İlk stok alımı', 1),
(3, 1, 20, 15000.00, 'purchase', 'PO-2023-003', 'Laptop alımı', 1),
(1, 1, 5, 21999.99, 'sale', 'SO-2023-001', 'Online satış', 3);

-- Stok Transferi
INSERT INTO stock_transfers (product_id, from_warehouse_id, to_warehouse_id, quantity, created_by) VALUES
(2, 1, 2, 10, 5),
(3, 1, 3, 5, 5);

-- GPT Puanı: 90 / 100

-- GPT Önerileri:
-- 1. role_name, permission_name, usermail gibi alanlara NOT NULL zaten eklenmiş, ancak bazı metin alanlarına (örn: reference_id) da eklenmesi veri bütünlüğü sağlar.
-- 2. userpassword için UNIQUE zorunlu değil, doğru şekilde kaldırılmış. Aynı hash birden fazla kullanıcıda olabilir.
-- 3. user_phone gibi alanlarda VARCHAR(20) yerine VARCHAR(50) veya VARCHAR(25) kullanılması, uluslararası uyumluluk sağlar.
-- 4. user(usermail), role(role_name), permissions(permission_name) gibi sütunlara index eklenmesi rapor performansını artırır.
-- 5. audit_log tablosuna ileride "ip_address", "action_detail" gibi alanlar eklenebilir.
-- 6. products tablosuna barcode ve stock_unit gibi alanlar, daha kapsamlı bir sistem sağlar.
-- 7. Gelecekte müşteri (customer) ve tedarikçi (supplier) tabloları eklenerek yapı genişletilebilir.
-- 8. Trigger yapıları çok iyi kurgulanmış, ancak karmaşık işlemlerde işlem izleyici/log (trigger işlemi başarısızsa hata logu) mantığı da entegre edilebilir.
-- 9. low_stock_alerts görünümüne `CASE` ile renk veya risk seviyesi gibi etiketler eklenebilir (örn: LOW → "Kritik").

-- Genel Yorum: Mükemmel bir veritabanı tasarımı. Hem ölçeklenebilir hem de operasyonel olarak güçlü bir yapı kurmuşsun.
