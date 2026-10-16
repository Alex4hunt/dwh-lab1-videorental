/* Лабораторная работа №1
   Вариант 14: Система учета в видеопрокате
   СУБД: MySQL, 3NF */

-- ===== СПРАВОЧНИКИ =====
CREATE TABLE genre (
    genre_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
) COMMENT 'Жанры фильмов';

CREATE TABLE media_type (
    media_type_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(30) NOT NULL UNIQUE,
    daily_price DECIMAL(8,2) NOT NULL CHECK (daily_price > 0)
) COMMENT 'Типы носителей и тариф проката за сутки';

CREATE TABLE copy_status (
    status_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(30) NOT NULL UNIQUE
) COMMENT 'Статусы экземпляров';

CREATE TABLE job_position (
    position_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
) COMMENT 'Должности';

CREATE TABLE payment_method (
    payment_method_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(30) NOT NULL UNIQUE
) COMMENT 'Способы оплаты';

-- ===== ОСНОВНЫЕ СУЩНОСТИ =====
CREATE TABLE movie (
    movie_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    release_year SMALLINT,
    duration_min SMALLINT CHECK (duration_min > 0),
    description TEXT,
    genre_id INT NOT NULL,
    FOREIGN KEY (genre_id) REFERENCES genre(genre_id)
) COMMENT 'Каталог фильмов';

CREATE TABLE copy (
    copy_id INT AUTO_INCREMENT PRIMARY KEY,
    inventory_number VARCHAR(20) NOT NULL UNIQUE,
    movie_id INT NOT NULL,
    media_type_id INT NOT NULL,
    status_id INT NOT NULL,
    purchase_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    FOREIGN KEY (movie_id) REFERENCES movie(movie_id),
    FOREIGN KEY (media_type_id) REFERENCES media_type(media_type_id),
    FOREIGN KEY (status_id) REFERENCES copy_status(status_id)
) COMMENT 'Физические экземпляры (диски)';

CREATE TABLE customer (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    last_name VARCHAR(50) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    middle_name VARCHAR(50),
    phone VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(100) UNIQUE,
    registered_at DATE NOT NULL DEFAULT (CURRENT_DATE)
) COMMENT 'Клиенты';

CREATE TABLE employee (
    employee_id INT AUTO_INCREMENT PRIMARY KEY,
    last_name VARCHAR(50) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    middle_name VARCHAR(50),
    position_id INT NOT NULL,
    hired_at DATE NOT NULL DEFAULT (CURRENT_DATE),
    FOREIGN KEY (position_id) REFERENCES job_position(position_id)
) COMMENT 'Сотрудники';

-- ===== ОПЕРАЦИИ ПРОКАТА =====
CREATE TABLE rental (
    rental_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    employee_id INT NOT NULL,
    rental_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    planned_return_date DATE NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id),
    FOREIGN KEY (employee_id) REFERENCES employee(employee_id)
) COMMENT 'Выдача дисков клиенту (шапка заказа)';

CREATE TABLE rental_item (
    rental_id INT NOT NULL,
    copy_id INT NOT NULL,
    price_per_day DECIMAL(8,2) NOT NULL CHECK (price_per_day > 0),
    returned_at DATETIME NULL,
    PRIMARY KEY (rental_id, copy_id),
    FOREIGN KEY (rental_id) REFERENCES rental(rental_id) ON DELETE CASCADE,
    FOREIGN KEY (copy_id) REFERENCES copy(copy_id)
) COMMENT 'Позиции заказа; returned_at = NULL, если диск не возвращен';

CREATE TABLE payment (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    rental_id INT NOT NULL,
    payment_method_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    paid_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (rental_id) REFERENCES rental(rental_id),
    FOREIGN KEY (payment_method_id) REFERENCES payment_method(payment_method_id)
) COMMENT 'Платежи по заказам';

-- ===== ТЕСТОВЫЕ ДАННЫЕ =====
INSERT INTO genre(name) VALUES ('Боевик'), ('Комедия'), ('Драма'), ('Фантастика');
INSERT INTO media_type(name, daily_price) VALUES ('DVD', 50.00), ('Blu-ray', 80.00);
INSERT INTO copy_status(name) VALUES ('В наличии'), ('Выдан'), ('Списан');
INSERT INTO job_position(name) VALUES ('Продавец-кассир'), ('Администратор');
INSERT INTO payment_method(name) VALUES ('Наличные'), ('Карта');

INSERT INTO movie(title, release_year, duration_min, genre_id) VALUES
    ('Матрица', 1999, 136, 4),
    ('Один дома', 1990, 103, 2),
    ('Побег из Шоушенка', 1994, 142, 3);

INSERT INTO copy(inventory_number, movie_id, media_type_id, status_id) VALUES
    ('INV-0001', 1, 1, 1),
    ('INV-0002', 1, 2, 2),
    ('INV-0003', 2, 1, 1),
    ('INV-0004', 3, 1, 1);

INSERT INTO customer(last_name, first_name, phone) VALUES
    ('Иванов', 'Иван', '+998901234567'),
    ('Петрова', 'Анна', '+998907654321');

INSERT INTO employee(last_name, first_name, position_id) VALUES ('Сидоров', 'Олег', 1);

INSERT INTO rental(customer_id, employee_id, planned_return_date)
VALUES (1, 1, DATE_ADD(CURRENT_DATE, INTERVAL 3 DAY));
INSERT INTO rental_item(rental_id, copy_id, price_per_day) VALUES (1, 2, 80.00);
INSERT INTO payment(rental_id, payment_method_id, amount) VALUES (1, 1, 240.00);

-- ===== ПРОВЕРОЧНЫЙ ЗАПРОС =====
SELECT c.last_name, m.title, mt.name AS media, ri.price_per_day, r.planned_return_date
FROM rental r
JOIN customer c     ON c.customer_id = r.customer_id
JOIN rental_item ri ON ri.rental_id = r.rental_id
JOIN copy cp        ON cp.copy_id = ri.copy_id
JOIN movie m        ON m.movie_id = cp.movie_id
JOIN media_type mt  ON mt.media_type_id = cp.media_type_id;