-- Veritabanı seç
CREATE DATABASE IF NOT EXISTS user_roles;
USE user_roles;

-- 1. roleauthority tablosu
CREATE TABLE roleauthority (
    roleauthorityId INT AUTO_INCREMENT PRIMARY KEY,
    roleauthorityname VARCHAR(20) NOT NULL,
    authorityRead TINYINT(1) DEFAULT 1,
    authorityWrite TINYINT(1) DEFAULT 0,
    authorityUpdate TINYINT(1) DEFAULT 0,
    authorityDelete TINYINT(1) DEFAULT 0
);

-- 2. role tablosu
CREATE TABLE role (
    role_id INT AUTO_INCREMENT PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL UNIQUE,
    role_description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    is_delete BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    roleauthorityId INT NOT NULL,
    CONSTRAINT fk_roleauthority FOREIGN KEY (roleauthorityId) REFERENCES roleauthority(roleauthorityId)
);

-- 3. roleauthority örnek veriler
INSERT INTO roleauthority (roleauthorityname, authorityRead, authorityWrite, authorityUpdate, authorityDelete) VALUES
('Admin',     1, 1, 1, 1),
('Editor',    1, 1, 1, 0),
('Viewer',    1, 0, 0, 0),
('Moderator', 1, 1, 0, 0);

-- 4. role örnek veriler
INSERT INTO role (role_name, role_description, roleauthorityId) VALUES
('Super Admin',     'Tüm sistem üzerinde tam yetkilidir.',          1),
('Content Editor',  'İçerikleri oluşturur ve düzenler.',           2),
('Read Only User',  'Sadece verileri okuyabilir.',                 3),
('Forum Moderator', 'Forum gönderilerini yönetebilir.',            4);

-- 5. user tablosu (role_id ile bağlı)
CREATE TABLE user (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    usermail VARCHAR(255) NOT NULL UNIQUE,
    userpassword VARCHAR(255) NOT NULL,
    user_fullname VARCHAR(100) NOT NULL,
    user_phone VARCHAR(15) NOT NULL,
    user_address TEXT,
    user_roleid INT DEFAULT 1 NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_user_role FOREIGN KEY (user_roleid) REFERENCES role(role_id)
);

-- 6. user örnek veriler
INSERT INTO user (usermail, userpassword, user_fullname, user_phone, user_address, user_roleid) VALUES
('admin@example.com',   'hashedpassword123', 'Ali Admin',    '05001112233', 'İstanbul', 1),
('editor@example.com',  'hashedpassword456', 'Ece Editor',   '05002223344', 'Ankara',   2),
('viewer@example.com',  'hashedpassword789', 'Veli Viewer',  '05003334455', 'İzmir',    3);
