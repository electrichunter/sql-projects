CREATE DATABASE IF NOT EXISTS Product_list;
USE Product_list;
-- 1. product tablosu
CREATE TABLE product (
    productId INT AUTO_INCREMENT PRIMARY KEY,
    productName VARCHAR(50) NOT NULL,
    productDescription TEXT,
    productPrice DECIMAL(10, 2) NOT NULL,
    productStock INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)
ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
-- 2. category tablosu
CREATE TABLE category ( 
    categoryId INT AUTO_INCREMENT PRIMARY KEY,
    categoryName VARCHAR(50) NOT NULL,
    categoryDescription TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)
ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
-- 3. product_category tablosu (N:N ilişki)

CREATE TABLE product_category (
    productId INT NOT NULL,
    categoryId INT NOT NULL,
    PRIMARY KEY (productId, categoryId),
    CONSTRAINT fk_product FOREIGN KEY (productId) REFERENCES product(productId),
    CONSTRAINT fk_category FOREIGN KEY (categoryId) REFERENCES category(categoryId)
)
ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
-- 4. product_review tablosu
CREATE TABLE product_review (
    reviewId INT AUTO_INCREMENT PRIMARY KEY,
    productId INT NOT NULL,
    customerId INT NOT NULL,
    reviewText TEXT,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_product_review FOREIGN KEY (productId) REFERENCES product(productId),
    CONSTRAINT fk_customer_review FOREIGN KEY (customerId) REFERENCES customer(customerid)
)
ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
-- 5. product_image tablosu         

CREATE TABLE product_image (
    imageId INT AUTO_INCREMENT PRIMARY KEY,
    productId INT NOT NULL,
    imageUrl VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_product_image FOREIGN KEY (productId) REFERENCES product(productId)
)   
ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
-- 6. product_tag tablosu (N:N ilişki)
CREATE TABLE product_tag (
    productId INT NOT NULL,
    tagId INT NOT NULL,
    PRIMARY KEY (productId, tagId),
    CONSTRAINT fk_product_tag_product FOREIGN KEY (productId) REFERENCES product(productId),
    CONSTRAINT fk_product_tag_tag FOREIGN KEY (tagId) REFERENCES tag(tagId)
)
ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
-- 7. tag tablosu
CREATE TABLE tag (
    tagId INT AUTO_INCREMENT PRIMARY KEY,
    tagName VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)
ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
-- 8. product_wishlist tablosu
CREATE TABLE product_wishlist (

    wishlistId INT AUTO_INCREMENT PRIMARY KEY,
    productId INT NOT NULL,
    customerId INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_product_wishlist_product FOREIGN KEY (productId) REFERENCES product(productId),
    CONSTRAINT fk_product_wishlist_customer FOREIGN KEY (customerId) REFERENCES customer(customerid)
)
ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- GPT Puanı: 93 / 100

-- GPT Önerileri:
-- 1. Tabloların genel yapısı ve ilişkilendirmeler başarılı, N:N ilişkiler doğru tanımlanmış.
-- 2. `product_review`, `product_wishlist` tabloları `customer` tablosuna referans veriyor fakat bu scriptte `customer` tablosu tanımlı değil. Eksik.
-- 3. `product_tag` tablosu, `tag` tablosuna referans veriyor; ancak `tag` tablosu **sonra** tanımlanmış. `tag` tablosu daha önce tanımlanmalı ya da `FOREIGN_KEY_CHECKS` geçici olarak devre dışı bırakılmalı.
-- 4. `rating` için CHECK kullanımı doğru ancak MySQL 8+ dışında çalışmayabilir. Uyumlu sürüm kontrol edilmeli.
-- 5. Bazı alanlara (`tagName`, `categoryName`, `imageUrl`, `productName`) `UNIQUE` eklenmesi düşünülebilir. Tekil isimler varsa veri tekrarı engellenir.
-- 6. `productStock` alanı için negatif değerleri engellemek adına `CHECK (productStock >= 0)` eklenebilir.
-- 7. `productPrice` için `CHECK (productPrice >= 0)` önerilir.
-- 8. Tüm tablolar `utf8mb4` ve `InnoDB` ile tutarlı, bu iyi bir pratik.

