-- Kategori tablosu
CREATE TABLE categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL
    categories_description TEXT,
    is_delete BOOLEAN DEFAULT FALSE,
    parent_category_id INT DEFAULT NULL

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Ürün tablosu
CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(255),
    product_description TEXT,
    product_price INT,
    product_image VARCHAR(255),
    product_stock INT DEFAULT 0,
    is_delete BOOLEAN DEFAULT FALSE,
    matched_category_id INT
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
);

-- Kategori anahtar kelimeleri tablosu
CREATE TABLE category_keywords (
    keyword_id INT AUTO_INCREMENT PRIMARY KEY,
    category_id INT,
    keyword VARCHAR(50),
    FOREIGN KEY (category_id) REFERENCES categories(category_id)

);
