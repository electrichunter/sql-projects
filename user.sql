CREATE DATABASE IF NOT EXISTS login;
USE login;

-- 1. roleauthority tablosu (öncelikle oluşturulmalı çünkü role bu tabloya referans veriyor)
CREATE TABLE roleauthority (
    roleauthorityId INT AUTO_INCREMENT PRIMARY KEY,
    roleauthorityname VARCHAR(20),
    authorityRead TINYINT(1) DEFAULT 1,
    authorityWrite TINYINT(1) DEFAULT 0,
    authorityUpdate TINYINT(1) DEFAULT 0,
    authorityDelete TINYINT(1) DEFAULT 0
);

-- 2. role tablosu
CREATE TABLE role (
    roleid INT AUTO_INCREMENT PRIMARY KEY,
    rolename VARCHAR(20) NOT NULL,
    roleauthorityId INT NOT NULL,
    CONSTRAINT fk_role_roleauthority FOREIGN KEY (roleauthorityId) REFERENCES roleauthority(roleauthorityId)
);

-- 3. customer tablosu
CREATE TABLE customer (
    customerid INT AUTO_INCREMENT PRIMARY KEY,
    customermail VARCHAR(50) NOT NULL,
    customername VARCHAR(50) NOT NULL,
    customerpassword VARCHAR(255) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_active TINYINT(1) DEFAULT 1,
    role_id INT NOT NULL,
    CONSTRAINT fk_customer_role FOREIGN KEY (role_id) REFERENCES role(roleid)
);
 

-- GPT Puanı: 90 / 100

-- GPT Önerileri:
-- 1. roleauthorityname, rolename ve customermail alanlarına NOT NULL eklenmeli.
-- 2. customerpassword için UNIQUE zorunlu değil, güvenlik açısından kaldırılabilir.
-- 3. roleauthorityname, rolename ve customermail alanlarına INDEX eklenmesi performans sağlar.
-- 4. VARCHAR(20) yerine bazı alanlar için VARCHAR(50) daha uygun olabilir.
