-- Veritabanı Oluşturma
CREATE DATABASE IF NOT EXISTS inventory_system;
USE inventory_system;

-- 1. İzinler Tablosu (Yeni esnek yetki yapısı)
CREATE TABLE permissions (
    permission_id INT AUTO_INCREMENT PRIMARY KEY,
    permission_name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT
);

-- 2. Roller Tablosu
CREATE TABLE role (
    role_id INT AUTO_INCREMENT PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL UNIQUE,
    role_description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    is_delete BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 3. Rol-İzin İlişki Tablosu (Çoktan-çoğa)
CREATE TABLE role_permissions (
    role_id INT NOT NULL,
    permission_id INT NOT NULL,
    PRIMARY KEY (role_id, permission_id),
    FOREIGN KEY (role_id) REFERENCES role(role_id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(permission_id) ON DELETE CASCADE
);

-- 4. Kullanıcılar Tablosu
CREATE TABLE user (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    usermail VARCHAR(255) NOT NULL UNIQUE,
    userpassword VARCHAR(255) NOT NULL COMMENT 'bcrypt ile hashlenmiş şifre',
    user_fullname VARCHAR(100) NOT NULL,
    user_phone VARCHAR(15) NOT NULL,
    user_address TEXT,
    user_roleid INT DEFAULT 1 NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_roleid) REFERENCES role(role_id)
);

-- 5. Ürünler Tablosu
CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    sku VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 6. Depolar Tablosu
CREATE TABLE warehouses (
    warehouse_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    location VARCHAR(200) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 7. Stok Hareketleri Tablosu (İyileştirmelerle)
CREATE TABLE stock_movements (
    movement_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    warehouse_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    movement_type ENUM('purchase', 'sale', 'return', 'adjustment', 'transfer') NOT NULL,
    movement_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reference_id VARCHAR(100),
    notes TEXT,
    created_by INT NOT NULL,
    
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id),
    FOREIGN KEY (created_by) REFERENCES user(user_id)
);

-- 8. Geçerli Stok Görünümü
CREATE VIEW current_stock AS
SELECT 
    p.product_id,
    p.sku,
    p.name AS product_name,
    w.warehouse_id,
    w.name AS warehouse_name,
    SUM(
        CASE 
            WHEN sm.movement_type IN ('purchase', 'return') THEN sm.quantity
            WHEN sm.movement_type IN ('sale', 'adjustment') THEN -sm.quantity
            ELSE 0 
        END
    ) AS current_quantity
FROM stock_movements sm
JOIN products p ON sm.product_id = p.product_id
JOIN warehouses w ON sm.warehouse_id = w.warehouse_id
GROUP BY p.product_id, w.warehouse_id;

-- 9. Kullanıcı İzin Görünümü
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

-- 10. İndeksler (Performans için)
CREATE INDEX idx_user_role ON user(user_roleid);
CREATE INDEX idx_stock_product ON stock_movements(product_id);
CREATE INDEX idx_stock_warehouse ON stock_movements(warehouse_id);
CREATE INDEX idx_stock_created_by ON stock_movements(created_by);
CREATE INDEX idx_stock_movement_date ON stock_movements(movement_date);

-- Örnek Veriler
INSERT INTO permissions (permission_name, description) VALUES
('stock_read', 'Stok bilgilerini görüntüleme'),
('stock_write', 'Yeni stok hareketi oluşturma'),
('stock_update', 'Stok hareketlerini güncelleme'),
('stock_delete', 'Stok hareketlerini silme'),
('user_manage', 'Kullanıcı yönetimi');

INSERT INTO role (role_name, role_description) VALUES
('Sistem Yöneticisi', 'Tüm sistem üzerinde tam yetki'),
('Stok Yöneticisi', 'Stok hareketlerini yönetir'),
('Satış Temsilcisi', 'Satış işlemlerini yönetir'),
('Raporlama Uzmanı', 'Sadece raporları görüntüler');

INSERT INTO role_permissions (role_id, permission_id) VALUES
(1, 1), (1, 2), (1, 3), (1, 4), (1, 5),  -- Sistem Yöneticisi
(2, 1), (2, 2), (2, 3),                   -- Stok Yöneticisi
(3, 1), (3, 2),                           -- Satış Temsilcisi
(4, 1);                                   -- Raporlama Uzmanı

INSERT INTO user (usermail, userpassword, user_fullname, user_phone, user_address, user_roleid) VALUES
('admin@firma.com', '$2y$10$EXAMPLEHASH', 'Ahmet Yılmaz', '05551112233', 'İstanbul', 1),
('stok@firma.com', '$2y$10$EXAMPLEHASH', 'Mehmet Demir', '05552223344', 'Ankara', 2),
('satis@firma.com', '$2y$10$EXAMPLEHASH', 'Ayşe Kaya', '05553334455', 'İzmir', 3);

INSERT INTO products (name, sku, description) VALUES
('iPhone 13 Pro', 'IP13P-128-BLK', '128GB Siyah iPhone 13 Pro'),
('Samsung Galaxy S22', 'SGS22-256-BLUE', '256GB Mavi Samsung Galaxy S22');

INSERT INTO warehouses (name, location) VALUES
('Merkez Depo', 'İstanbul, Maslak'),
('Anadolu Deposu', 'Ankara, Çankaya');

INSERT INTO stock_movements (product_id, warehouse_id, quantity, movement_type, reference_id, notes, created_by) VALUES
(1, 1, 50, 'purchase', 'PO-2023-001', 'İlk stok alımı', 1),
(2, 1, 30, 'purchase', 'PO-2023-002', 'İlk stok alımı', 1),
(1, 1, -5, 'sale', 'SO-2023-001', 'Online satış', 3);