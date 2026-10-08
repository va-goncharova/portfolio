-- Таблица производителей
CREATE TABLE Manufacturer (
    manufacturer_id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    country VARCHAR(100),
    contact_person VARCHAR(100),
    phone VARCHAR(20),
    email VARCHAR(100),
    website VARCHAR(200)
);

-- Таблица категорий
CREATE TABLE Category(
    category_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    parent_category_id INTEGER REFERENCES Category(category_id)
);

-- Таблица поставщиков
CREATE TABLE Supplier (
    supplier_id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    contact_phone VARCHAR(20),
    email VARCHAR(100),
    address TEXT,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    payment_terms VARCHAR(50)
);

-- Таблица товаров
CREATE TABLE Product (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    category_id INTEGER NOT NULL REFERENCES Category(category_id),
    manufacturer_id INTEGER NOT NULL REFERENCES Manufacturer(manufacturer_id),
    supplier_id INTEGER REFERENCES Supplier(supplier_id),
    price DECIMAL(10,2) NOT NULL CHECK (price > 0),
    purchase_price DECIMAL(10,2) NOT NULL,
    barcode VARCHAR(50) UNIQUE,
    unit VARCHAR(20) DEFAULT 'uint',
    min_quantity INTEGER DEFAULT 10 CHECK (min_quantity >= 0),
    max_quantity INTEGER DEFAULT 100 CHECK (max_quantity >= min_quantity),
    is_active BOOLEAN DEFAULT TRUE,
    description TEXT,
    created_date DATE DEFAULT CURRENT_DATE
);

-- Таблица склада
CREATE TABLE Warehouse (
    warehouse_id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL REFERENCES Product(product_id),
    quantity INTEGER NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    last_restock_date DATE,
    location VARCHAR(100),
    shelf_life DATE,
    batch_number VARCHAR(50)
);

-- Таблица клиентов
CREATE TABLE Customer (
    customer_id SERIAL PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(100),
    customer_type VARCHAR(20) DEFAULT 'розничный' CHECK (customer_type IN ('розничный', 'оптовый')),
    discount DECIMAL(5,2) DEFAULT 0 CHECK (discount >= 0 AND discount <= 100),
    registration_date DATE DEFAULT CURRENT_DATE,
    address TEXT,
    notes TEXT
);

-- Таблица сотрудников
CREATE TABLE Employee (
    employee_id SERIAL PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    position VARCHAR(100) NOT NULL,
    hire_date DATE NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(100),
    salary DECIMAL(10,2) CHECK (salary >= 0),
    is_active BOOLEAN DEFAULT TRUE,
    login VARCHAR(50) UNIQUE,
    password_hash VARCHAR(255)
);

-- Таблица продаж
CREATE TABLE Sale (
    sale_id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL REFERENCES Product(product_id),
    employee_id INTEGER NOT NULL REFERENCES Employee(employee_id),
    customer_id INTEGER REFERENCES Customer(customer_id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price > 0),
    total_sum DECIMAL(10,2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
    sale_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    payment_method VARCHAR(20) DEFAULT 'наличные' CHECK (payment_method IN ('наличные', 'карта', 'перевод')),
    receipt_number VARCHAR(50) UNIQUE
);

-- Таблица заказов поставщикам
CREATE TABLE SupplierOrder (
    order_id SERIAL PRIMARY KEY,
    supplier_id INTEGER NOT NULL REFERENCES Supplier(supplier_id),
    product_id INTEGER NOT NULL REFERENCES Product(product_id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_cost DECIMAL(10,2) NOT NULL CHECK (unit_cost > 0),
    total_cost DECIMAL(10,2) GENERATED ALWAYS AS (quantity * unit_cost) STORED,
    order_date DATE DEFAULT CURRENT_DATE,
    expected_delivery_date DATE,
    actual_delivery_date DATE,
    status VARCHAR(30) DEFAULT 'в обработке' CHECK (status IN ('в обработке', 'подтвержден', 'отгружен', 'доставлен', 'отменен')),
    notes TEXT
);

-- Таблица для учета цен (история изменения цен)
CREATE TABLE PriceHistory (
    price_id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL REFERENCES Product(product_id),
    old_price DECIMAL(10,2),
    new_price DECIMAL(10,2) NOT NULL,
    change_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by INTEGER REFERENCES Employee(employee_id),
    reason VARCHAR(200)
);
-- ЗАПОЛНЕНИЕ ТЕСТОВЫМИ ДАННЫМИ

-- Производители
INSERT INTO manufacturers (name, country) VALUES
('Procter & Gamble', 'USA'),
('Henkel', 'Germany'),
('Splat', 'Russia'),
('Unilever', 'UK');

-- Категории
INSERT INTO categories (name, description) VALUES
('Моющие средства', 'Для уборки дома'),
('Стиральные порошки', 'Для стирки белья'),
('Освежители воздуха', 'Ароматизаторы'),
('Средства для посуды', 'Для мытья посуды');

-- Поставщики
INSERT INTO suppliers (name, phone, email) VALUES
('ООО ХимСнаб', '+7-495-111-22-33', 'info@himsnab.ru'),
('ИП Иванов', '+7-916-222-33-44', 'ivanov@mail.ru'),
('АО БытХим', '+7-495-333-44-55', 'byt@him.ru');

-- Товары
INSERT INTO products (name, category_id, manufacturer_id, supplier_id, price, barcode, quantity, min_quantity) VALUES
('Fairy 500 мл', 4, 1, 1, 150.00, '4601234567890', 45, 20),
('Миф гель 1.5 л', 2, 3, 2, 250.00, '4602345678901', 32, 15),
('Glade 300 мл', 3, 1, 1, 120.00, '4603456789012', 120, 30),
('Доместос 750 мл', 1, 2, 3, 180.00, '4604567890123', 65, 25);

-- Клиенты
INSERT INTO customers (name, phone, email, discount) VALUES
('Иванов Иван', '+7-915-123-45-67', 'ivanov@mail.ru', 0),
('Петрова Мария', '+7-916-987-65-43', 'petrova@gmail.com', 5),
('ООО Чистый дом', '+7-495-765-43-21', 'clean@house.ru', 15);

-- Сотрудники
INSERT INTO employees (name, position, hire_date) VALUES
('Сидорова Анна', 'продавец', '2023-01-15'),
('Кузнецов Дмитрий', 'кассир', '2023-03-20'),
('Васильев Петр', 'менеджер', '2022-11-10');

-- Продажи
INSERT INTO sales (product_id, customer_id, employee_id, quantity, price) VALUES
(1, 1, 1, 2, 150.00),
(2, 2, 2, 1, 250.00),
(3, 3, 1, 5, 120.00),
(1, 2, 3, 3, 150.00);

-- Заказы поставщикам
INSERT INTO supplier_orders (supplier_id, product_id, quantity, status) VALUES
(1, 1, 50, 'доставлен'),
(2, 2, 30, 'в пути'),
(3, 3, 100, 'ожидает');
-- ПРОСТЫЕ ЗАПРОСЫ ДЛЯ ПРОВЕРКИ

-- Все товары с категориями и производителями
SELECT 
    p.name as товар, 
    c.name as категория, 
    m.name as производитель, 
    p.price as цена, 
    p.quantity as остаток 
FROM products p 
JOIN categories c ON p.category_id = c.id 
JOIN manufacturers m ON p.manufacturer_id = m.id 
WHERE p.is_active = TRUE 
ORDER BY p.name;

-- Продажи за сегодня
SELECT 
    s.sale_date as дата, 
    p.name as товар, 
    c.name as клиент, 
    e.name as продавец, 
    s.quantity as количество, 
    s.price as цена_за_единицу, 
    (s.quantity * s.price) as сумма 
FROM sales s
JOIN products p ON s.product_id = p.id 
JOIN customers c ON s.customer_id = c.id 
JOIN employees e ON s.employee_id = e.id 
WHERE DATE(s.sale_date) = CURRENT_DATE 
ORDER BY s.sale_date DESC;

-- Товары, требующие заказа
SELECT 
    p.name as товар, 
    p.quantity as остаток, 
    p.min_quantity as минимум, 
    s.name as поставщик, 
    s.phone as телефон_поставщика 
FROM products p 
JOIN suppliers s ON p.supplier_id = s.id 
WHERE p.quantity <= p.min_quantity 
ORDER BY p.quantity;

-- Клиенты с покупками
SELECT 
    c.name as клиент, 
    c.phone as телефон, 
    COUNT(s.id) as количество_покупок, 
    SUM(s.quantity * s.price) as общая_сумма 
FROM customers c 
LEFT JOIN sales s ON c.id = s.customer_id 
GROUP BY c.id, c.name, c.phone 
ORDER BY общая_сумма DESC NULLS LAST;
-- ИНДЕКСЫ ДЛЯ УСКОРЕНИЯ
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_manufacturer ON products(manufacturer_id);
CREATE INDEX idx_sales_date ON sales(sale_date);
CREATE INDEX idx_sales_product ON sales(product_id);
CREATE INDEX idx_sales_customer ON sales(customer_id);

-- ВИДЫ (VIEWS) ДЛЯ ОТЧЕТОВ

-- Остатки товаров
CREATE VIEW stock_view AS
SELECT 
    p.id,
    p.name,
    c.name as category,
    m.name as manufacturer,
    p.price,
    p.quantity,
    p.min_quantity,
    CASE 
        WHEN p.quantity = 0 THEN 'нет в наличии'
        WHEN p.quantity <= p.min_quantity THEN 'мало'
        ELSE 'достаточно'
    END as status
FROM products p
JOIN categories c ON p.category_id = c.id
JOIN manufacturers m ON p.manufacturer_id = m.id;

-- Ежедневные продажи
CREATE VIEW daily_sales_view AS
SELECT 
    DATE(s.sale_date) as date, 
    p.name as product, 
    SUM(s.quantity) as total_quantity, 
    SUM(s.quantity * s.price) as total_amount, 
    COUNT(*) as transactions 
FROM sales s 
JOIN products p ON s.product_id = p.id 
GROUP BY DATE(s.sale_date), p.name 
ORDER BY date DESC, total_amount DESC;

-- ТРИГГЕР ДЛЯ ОБНОВЛЕНИЯ ОСТАТКОВ
CREATE OR REPLACE FUNCTION update_product_quantity()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Уменьшаем остаток при продаже
        UPDATE products 
        SET quantity = quantity - NEW.quantity 
        WHERE id = NEW.product_id;
    ELSIF TG_OP = 'DELETE' THEN
        -- Возвращаем остаток при удалении продажи
        UPDATE products 
        SET quantity = quantity + OLD.quantity 
        WHERE id = OLD.product_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_sale
AFTER INSERT OR DELETE ON sales
FOR EACH ROW
EXECUTE FUNCTION update_product_quantity();

-- ПРОСТОЙ ОТЧЕТ: ТОП-5 ТОВАРОВ
SELECT 
    p.name as товар, 
    COUNT(s.id) as проданных_раз, 
    SUM(s.quantity) as проданное_количество, 
    SUM(s.quantity * s.price) as общая_выручка 
FROM sales s 
JOIN products p ON s.product_id = p.id 
GROUP BY p.id, p.name 
ORDER BY общая_выручка DESC 
LIMIT 5;
